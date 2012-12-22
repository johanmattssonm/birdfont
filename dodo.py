import os
import glob
import subprocess
from os.path import join


from doit.tools import run_once
from doit.action import CmdAction


############ helpers

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


###############################################

DOIT_CONFIG = {
    'verbosity': 2,
    'default_tasks': [
        'build',
        'libbirdfont',
        'birdfont',
        'birdfont_export',
        'compile_translations',
        'man'
        ],
    }

LIBS = [
    'glib-2.0',
    'libxml-2.0',
    'gio-2.0',
    'libsoup-2.4',
    'cairo',
    'gdk-pixbuf-2.0',
    'webkit-1.0',
    ]


def task_pkg_flags():
    """get compiler flags for libs/pkgs """
    for pkg in LIBS:
        cmd = 'pkg-config --cflags --libs {pkg}'
        yield {
            'name': pkg,
            'actions': [CmdAction(cmd.format(pkg=pkg), save_out='out')],
            'uptodate': [run_once],
            }


def task_build ():
    if not os.path.exists ("build/configured"):
        print ("Project is not configured")
        exit (1)

    subprocess.check_output ('mkdir -p build', shell=True)
    subprocess.check_output ('touch build/installed', shell=True)

    return  {
        'actions': ['echo "Build"'],
        }




####################### vala build tool


class Vala(object):
    """helper to generate tasks to compile vala code"""

    def __init__(self, src, build, pkg_libs, library=None, vala_deps=None):
        self.src = src
        self.build = build
        self.library = library
        self.pkg_libs = pkg_libs
        self.vala_deps = vala_deps or []

        self.vala = list(glob.glob(src + '/*.vala'))
        self.cc = [join(build, f.replace('.vala', '.c')) for f in self.vala]
        self.obj = [join(build, f.replace('.vala', '.o')) for f in self.vala]
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
        return {
            'name': 'compile_c',
            'actions': [ action ],
            'file_dep': self.vala + dep_vapi,
            'targets': targets,
            }


    def gen_o(self, opts):
        """compile C files to obj `.o` """
        def compile_cmd(conf, opts, libs, pos):
            flags = [conf[l].strip() for l in libs]
            return cmd('gcc', opts, flags, pos)

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
            return cmd('gcc', opts, flags)

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
            return cmd('gcc', opts, flags)

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



#########  BIRDFONT

libbird = Vala(src='libbirdfont', build='build', library='birdfont',
                pkg_libs=LIBS)
def task_libbirdfont():
    yield libbird.gen_c(['--enable-experimental-non-null', '--thread'])
    yield libbird.gen_o(['-fPIC', """-D 'GETTEXT_PACKAGE="birdfont"'"""])
    yield libbird.gen_so()


def task_birdfont ():
    bird = Vala(src='birdfont', build='build', pkg_libs=LIBS, vala_deps=[libbird])
    yield bird.gen_c([])
    yield bird.gen_bin(["""-D 'GETTEXT_PACKAGE="birdfont"' """])


def task_birdfont_export ():
     exp = Vala(src='birdfont-export', build='build', pkg_libs=LIBS,
                vala_deps=[libbird])
     yield exp.gen_c([])
     yield exp.gen_bin(["""-D 'GETTEXT_PACKAGE="birdfont"' """])



def task_compile_translations ():
    """translate po files"""
    for f_name in glob.glob('po/*.po'):
        lang = os.path.relpath(f_name)[:-3] # remove ".po"
        build_path = "build/locale/" + lang + "/LC_MESSAGES/"
        target = build_path + "birdfont.mo"
        cmd = "msgfmt --output=%s %s" % (target, f_name)
        yield {
            'name': lang,
            'actions': ["mkdir -p " + build_path, cmd],
            'file_dep': [f_name],
            'targets': [ target ],
            }

def task_man():
    """gzip linux man pages"""
    for name in ("birdfont.1", "birdfont-export.1"):
        yield {
            'name': name,
            'file_dep': ['linux/%s' % name],
            'targets': ['build/%s.gz' % name],
            'actions': ["gzip -9 -c %(dependencies)s > %(targets)s"],
            }


def task_distclean ():
    return  {
        'actions': ['rm -rf build dodo.pyc libbirdfont/Config.vala'],
        }
