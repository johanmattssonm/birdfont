import os
import glob
import subprocess


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
        'birdfont',
        'birdfont_export',
        'libbirdfont_c',
        'libbirdfont_o',
        'libbirdfont_so',
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


def task_libbirdfont_c ():
    """translate code from vala to C and create .vapi"""
    options = [
        '--ccode', # output C code
        '--enable-experimental-non-null',
        '--thread',
        '--save-temps',
        ]

    # include binding for pakages
    params = {
        'basedir': './build/libbirdfont',
        'vapidir': './',
        'library': 'birdfont',
        'vapi': './build/birdfont.vapi',
        'header': './build/birdfont.h',
        'pkg': ['gtk+-2.0', 'libxml-2.0', 'webkit-1.0'],
        }

    src = 'libbirdfont/*.vala'
    actions = [ cmd('valac', options, params, src) ]
    file_dep = list(glob.glob(src))
    targets = ["build/" + f.replace('.vala', '.c') for f in file_dep]
    targets.extend([ 'build/birdfont.h', 'build/birdfont.vapi'])
    return {
        'actions': actions,
        'file_dep': file_dep,
        'targets': targets,
        }



def task_libbirdfont_o ():
    """compile C files to obj `.o` """
    def compile_cmd(conf, libs, pos):
        opts = ['-fPIC', """-D 'GETTEXT_PACKAGE="birdfont"'"""]
        flags = [conf[l].strip() for l in LIBS]
        return cmd('gcc', opts, flags, pos)

    for vala in glob.glob('libbirdfont/*.vala'):
        cee = vala.replace ('.vala', '.c')
        obj = vala.replace ('.vala', '.o')
        pos = ["-c build/" + cee,
               "-o build/" + obj ]

        yield {
            'name': obj,
            'file_dep': [ 'build/' + cee ],
            'actions': [ CmdAction((compile_cmd, [], {'pos':pos, 'libs':LIBS}))],
            'getargs': { 'conf': ('pkg_flags', 'out') },
            'targets': [ 'build/' + obj ],
            }


def task_libbirdfont_so():
    def compile_cmd(conf, libs):
        opts = ['-shared build/libbirdfont/*.o',
                '-o build/libbirdfont.so']
        flags = [conf[l].strip() for l in LIBS]
        return cmd('gcc', opts, flags)

    file_dep = []
    for vala in glob.glob('libbirdfont/*.vala'):
        file_dep.append("build/" + vala.replace ('.vala', '.o'))

    return {
        'actions': [ CmdAction((compile_cmd, [], {'libs':LIBS})) ],
        'getargs': { 'conf': ('pkg_flags', 'out') },
        'file_dep': file_dep,
        'targets': [ 'build/libbirdfont.so' ],
        }


def task_birdfont ():
    birdfont_sources = os.listdir('birdfont/')

    files = []
    for f in birdfont_sources:
        files += ["birdfont/" + f]
    files.append('build/birdfont.vapi')

    options = ['--ccode']
    params = {
        'basedir': './build/main',
        'pkg': ['gtk+-2.0', 'libxml-2.0', 'gdk-2.0', 'webkit-1.0'],
        }

    yield {
        'name': 'compile_birdfont_executable',
        'actions': [ cmd('valac', options, params,
                         './build/birdfont.vapi', './birdfont/*.vala') ],
        'file_dep': files,
        'targets': [ 'build/main/Main.c', 'build/main/GtkWindow.c' ],
        }

    build_action = """gcc ./build/main/*.c \
                      -D 'GETTEXT_PACKAGE="birdfont"' \
                      -I ./build/ -L ./build -l birdfont \
                      -o ./build/birdfont \
                      $(pkg-config --cflags --libs glib-2.0) \
                      $(pkg-config --cflags --libs libxml-2.0) \
                      $(pkg-config --cflags --libs gio-2.0) \
                      $(pkg-config --cflags --libs libsoup-2.4) \
                      $(pkg-config --cflags --libs gtk+-2.0) \
                      $(pkg-config --cflags --libs webkit-1.0)"""

    yield {
        'name': "build_birdfont_executable",
        'actions': [ build_action ],
        'file_dep': [ 'build/main/Main.c', 'build/libbirdfont.so'],
        'targets': [ 'build/birdfont' ],
        }


def task_birdfont_export ():
    birdfont_sources = os.listdir('birdfont-export/')

    files = []
    for f in birdfont_sources:
        files += ["birdfont-export/" + f]

    action = """valac \
                --basedir ./build/export \
                -C ./build/birdfont.vapi \
                ./birdfont-export/*.vala \
                -X ../build/libbirdfont/libbirdfont.so -X ./build/birdfont.h \
                --pkg gtk+-2.0 --pkg libxml-2.0 --pkg gdk-2.0 --pkg webkit-1.0"""

    yield {
        'name': 'compile_birdfont_export_executable',
        'actions': [ action ],
        'file_dep': files,
        'targets': [ 'build/export/BirdfontExport.c' ],
        'task_dep': ['libbirdfont_o'],
        }

    build_action = """gcc ./build/main/*.c \
                                -D 'GETTEXT_PACKAGE="birdfont"' \
                                -I ./build -L ./build -l birdfont \
                                -o ./build/birdfont-export \
                                $(pkg-config --cflags --libs glib-2.0) \
                                $(pkg-config --cflags --libs libxml-2.0) \
                                $(pkg-config --cflags --libs gio-2.0) \
                                $(pkg-config --cflags --libs libsoup-2.4) \
                                $(pkg-config --cflags --libs gtk+-2.0) \
                                $(pkg-config --cflags --libs webkit-1.0)"""

    yield {
        'name': "build_birdfont_export_executable",
        'actions': [ build_action ],
        'file_dep': [ 'build/export/BirdfontExport.c' ],
        'targets': [ 'build/birdfont-export' ],
        }


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
