import os
import glob
import subprocess

from doit.tools import run_once
from doit.action import CmdAction
from scripts.bavala import Vala
from scripts import version

VERSION = version.VERSION

DOIT_CONFIG = {
    'default_tasks': [
        'build',
        'libbirdfont',
        'birdfont',
        'birdfont_export',
        'compile_translations',
        'man'
        ],
    }

# external Vala libs
LIBS = [
    'glib-2.0',
    'libxml-2.0',
    'gio-2.0',
    'libsoup-2.4',
    'cairo',
    'gdk-pixbuf-2.0',
    'webkit-1.0',
    ]



def task_build ():
    if not os.path.exists ("build/configured"):
        print ("Project is not configured")
        exit (1)

    subprocess.check_output ('mkdir -p build', shell=True)
    subprocess.check_output ('touch build/installed', shell=True)

    return  {
        'actions': ['echo "Build"'],
        }

def task_pkg_flags():
    """get compiler flags for libs/pkgs """
    for pkg in LIBS:
        cmd = 'pkg-config --cflags --libs {pkg}'

        yield {
            'name': pkg,
            'actions': [CmdAction(cmd.format(pkg=pkg), save_out='out')],
            'uptodate': [run_once],
            }


valac_options = [
	'--enable-experimental-non-null',
	'--thread',
	'--enable-experimental',
	'--target-glib=2.34', # see bug 0000004
	'--define=LINUX'
	]	
libbird = Vala(src='libbirdfont', build='build', library='birdfont', pkg_libs=LIBS)
def task_libbirdfont():
    yield libbird.gen_c(valac_options)
    yield libbird.gen_o(['-fPIC', """-D 'GETTEXT_PACKAGE="birdfont"'"""])
    yield libbird.gen_so()


def task_birdfont ():
    bird = Vala(src='birdfont', build='build', pkg_libs=LIBS, vala_deps=[libbird])
    yield bird.gen_c(valac_options)
    yield bird.gen_bin(["""-D 'GETTEXT_PACKAGE="birdfont"' """])


def task_birdfont_export ():
     exp = Vala(src='birdfont-export', build='build', pkg_libs=LIBS,
                vala_deps=[libbird])
     yield exp.gen_c(valac_options)
     yield exp.gen_bin(["""-D 'GETTEXT_PACKAGE="birdfont"' """])




def task_compile_translations ():
    """translate po files"""
    for f_name in glob.glob('po/*.po'):
        lang = f_name.replace ("po/", "").replace (".po", "")
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
            'file_dep': ['resources/linux/%s' % name],
            'targets': ['build/%s.gz' % name],
            'actions': ["gzip -9 -c %(dependencies)s > %(targets)s"],
            }


def task_distclean ():
    return  {
        'actions': ['rm -rf .doit.db build bavala.pyc dodo.pyc libbirdfont/Config.vala'],
        }

