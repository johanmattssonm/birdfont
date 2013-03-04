"""bavala is a build-tool for Vala based on doit (http://pydoit.org)"""

import glob
import os
import sys
from os.path import join
from doit.action import CmdAction
import config
import fnmatch


def cmd(name, *args):
    """create string for command line"""
    parts = [name]
    for item in args:
        if isinstance(item, basestring):
            parts.append(item)
        elif isinstance(item, dict):
            for param, value in item.iteritems():
                if isinstance(value, basestring):
                    value = [value]
                parts.extend('--{0} {1}'.format(param, v) for v in value)
        else:
            parts.extend(item)
    return ' '.join(parts)


def get_sources_path (folder, pattern):
    files = []
    for root, dirnames, filenames in os.walk(folder):
        for filename in fnmatch.filter(filenames, pattern):
            files.append(os.path.join(root, filename))
    return files



def get_sources_name (folder, pattern):
    files = []
    for root, dirnames, filenames in os.walk(folder):
        for filename in fnmatch.filter(filenames, pattern):
            files.append(filename)
    return files



class Vala(object):
    """helper to generate tasks to compile vala code"""

    def __init__(self, src, build, pkg_libs, library=None, vala_deps=None):
        self.src = src
        self.build = build
        self.library = library
        self.pkg_libs = pkg_libs
        self.vala_deps = vala_deps or []

        self.vala = get_sources_path (src, '*.vala')
        self.c = get_sources_path (src, '*.c') # copy regular c sources
        self.cc = [join(build + '/' + src, f) for f in get_sources_name (src, '*.c') ]
        self.cc += [join(build + '/' + src, f.replace('.vala', '.c')) for f in get_sources_name (src, '*.vala')]
        self.obj = [f.replace('.c', '.o') for f in get_sources_name (src, '*.c')]
        self.obj += [join(build, f.replace('.vala', '.o')) for f in get_sources_name (src, '*.vala')]
        
        if library:
            self.header = join(build, library) + '.h'
            self.vapi = join(build, library) + '.vapi'
            self.so = join(build, src) + '.so'

    def gen_c(self, opts):
        """translate code from vala to C and create .vapi"""
        options = ['--ccode', '--save-temps']
        options.extend(opts)
        params = {
            'basedir': join(self.build, self.src),
            'vapidir': './',
            'pkg': self.pkg_libs,
            }
        if self.library:
            params['library'] = self.library
            params['vapi'] = self.vapi
            params['header'] = self.header

        dep_vapi = [d.vapi for d in self.vala_deps]
        action = cmd('valac', options, params, dep_vapi, self.vala)
        targets = self.cc[:]
        if self.library:
            targets += [self.header, self.vapi]
        
        for f in self.c:
            yield {
                'name': 'copy_c',
                'actions': [ 
                    'mkdir -p '+  self.build + '/' + self.src + '/', 
                    'cp ' + f + ' ' + self.build + '/' + self.src + '/'
                    ],
                }
        
        print (action)                     
        yield {
            'name': 'compile_c',
            'actions': [ action ],
            'file_dep': self.vala + dep_vapi,
            'targets': targets,
            }


    def gen_o(self, opts):
        """compile C files to obj `.o` """
        def compile_cmd(conf, opts, libs, pos):
            flags = [conf[l].strip() for l in libs]
            return cmd(config.CC, opts, flags, pos)

        for cc, obj in zip(self.cc, self.obj):
            pos = ["-c " + cc, "-o " + obj ]
            cmd_args = {'libs':self.pkg_libs, 'opts':opts, 'pos':pos}
            action = CmdAction((compile_cmd, [], cmd_args))
            yield {
                'name': obj.rsplit('/')[-1],
                'file_dep': [ cc ],
                'actions': [ action ],
                'getargs': { 'conf': ('pkg_flags', 'out') },
                'targets': [ obj ],
                }


    def gen_so(self):
        """generate ".so" lib file"""
        def compile_cmd(conf, libs):
            obj_glob = join(self.build, self.src, '*.o')
            opts = ['-shared ' + obj_glob,
                    '-o ' + self.so ]
            flags = [conf[l].strip() for l in libs]
            return cmd(config.CC, opts, flags)

        return {
            'name': self.so.rsplit('/')[-1],
            'actions': [ CmdAction((compile_cmd, [], {'libs':self.pkg_libs})) ],
            'getargs': { 'conf': ('pkg_flags', 'out') },
            'file_dep': self.obj,
            'targets': [ self.so ],
            }


    def gen_bin(self, opts):
        """generate binary"""
        def compile_cmd(conf, opts, libs):
            flags = [conf[l].strip() for l in libs]
            return cmd(config.CC, opts, flags)

        bin_path = join(self.build, 'bin')
        target = join(bin_path, self.src)
        opts = (self.cc + opts +
                ['-o ' + target, '-I ' + self.build, '-L ' + self.build] +
                ['-l ' + d.library for d in self.vala_deps])
        action = CmdAction((compile_cmd, [], {'opts':opts, 'libs':self.pkg_libs}))
        yield {
            'name': "bin",
            'actions': [ 'mkdir -p %s' % bin_path, action ],
            'getargs': { 'conf': ('pkg_flags', 'out') },
            'file_dep': self.cc + [ d.so for d in self.vala_deps ],
            'targets': [ target ],
            }



