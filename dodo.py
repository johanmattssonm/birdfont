"""
Copyright (C) 2012 2013 2014 2015 Eduardo Naufel Schettino and Johan Mattsson

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
"""

import os
import glob
import subprocess
import sys

from optparse import OptionParser
from doit.tools import run_once
from doit.action import CmdAction
from scripts.bavala import Vala
from scripts import version
from scripts.translations import compile_translations
from scripts import config

DOIT_CONFIG = {
    'default_tasks': [
        'build',
        'libbirdgems', 	
        'libbirdxml',
        'libbirdfont',
        'birdfont',
        'birdfont_autotrace',
        'birdfont_export',
        'birdfont_import',
        'compile_translations',
        'man'
        ],
    }

# external Vala libs
LIBS = [
    'sqlite3',
    'glib-2.0',
    'gio-2.0',
    'fontconfig',
    'cairo',
    'gdk-pixbuf-2.0',
    'webkitgtk-3.0',
    config.GEE,
    'libnotify'
    ]

if not config.POSIXVALA:
    LIBBIRD_XML_LIBS = [
        'glib-2.0',
	'posix'
    ]
else:
    LIBBIRD_XML_LIBS = [
        'posix',
	'posixtypes'
    ]

LIBBIRD_LIBS = [
	'glib-2.0'
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
	'--thread',
	'--enable-experimental-non-null',
	'--enable-experimental',
	'--target-glib=2.34', # see bug 0000004
	'--define=LINUX'
	]


if "bsd" in sys.platform:
    LIBBIRDXML_SO_VERSION='${LIBbirdxml_VERSION}'
else:
    LIBBIRDXML_SO_VERSION=version.LIBBIRDXML_SO_VERSION

libbirdxml = Vala(src='libbirdxml', build='build', library='birdxml', so_version=LIBBIRDXML_SO_VERSION, pkg_libs=LIBBIRD_XML_LIBS)
def task_libbirdxml():

    if config.POSIXVALA == True:
        yield libbirdxml.gen_c(valac_options + ['--profile posix'])
    else:
        yield libbirdxml.gen_c(valac_options)

    yield libbirdxml.gen_o(['-fPIC'])
    yield libbirdxml.gen_so()
    yield libbirdxml.gen_ln()
    

if "bsd" in sys.platform:
    LIBBIRDGEMS_SO_VERSION='${LIBbirdgems_VERSION}'
else:
    LIBBIRDGEMS_SO_VERSION=version.LIBBIRDGEMS_SO_VERSION

libbirdgems = Vala(src='libbirdgems', build='build', library='birdgems', so_version=LIBBIRDGEMS_SO_VERSION, pkg_libs=LIBBIRD_LIBS, vala_deps=[])
def task_libbirdgems():
    yield libbirdgems.gen_c(valac_options)
    yield libbirdgems.gen_o(['-fPIC'])
    yield libbirdgems.gen_so('-shared -L ./build -l m')
    yield libbirdgems.gen_ln()

if "bsd" in sys.platform:
    SO_VERSION='${LIBbirdfont_VERSION}'
else:
    SO_VERSION=version.SO_VERSION

libbird = Vala(src='libbirdfont', build='build', library='birdfont', so_version=SO_VERSION, pkg_libs=LIBS, vala_deps=[libbirdgems, libbirdxml])
def task_libbirdfont():
    yield libbird.gen_c(valac_options)
    yield libbird.gen_o(['-fPIC -I./build/', """-D 'GETTEXT_PACKAGE="birdfont"'"""])
    yield libbird.gen_so('-L ./build -l birdxml -L ./build -l birdgems')
    yield libbird.gen_ln()


def task_birdfont():
    bird = Vala(src='birdfont', build='build', pkg_libs=LIBS, vala_deps=[libbird, libbirdxml, libbirdgems])
    yield bird.gen_c(valac_options)
    yield bird.gen_bin(["""-D 'GETTEXT_PACKAGE="birdfont"' """])


def task_birdfont_autotrace():
     exp = Vala(src='birdfont-autotrace', build='build', pkg_libs=LIBS, vala_deps=[libbird, libbirdxml, libbirdgems])
     yield exp.gen_c(valac_options)
     yield exp.gen_bin(["""-D 'GETTEXT_PACKAGE="birdfont"' """])


def task_birdfont_export():
     exp = Vala(src='birdfont-export', build='build', pkg_libs=LIBS, vala_deps=[libbird, libbirdxml, libbirdgems])
     yield exp.gen_c(valac_options)
     yield exp.gen_bin(["""-D 'GETTEXT_PACKAGE="birdfont"' """])


def task_birdfont_import():
     exp = Vala(src='birdfont-import', build='build', pkg_libs=LIBS, vala_deps=[libbird, libbirdxml, libbirdgems])
     yield exp.gen_c(valac_options)
     yield exp.gen_bin(["""-D 'GETTEXT_PACKAGE="birdfont"' """])


def task_compile_translations ():
    """translate po files"""
    return  {
        'actions': [compile_translations]
        }

def task_man():
    """gzip linux man pages"""
    for name in ("birdfont.1", "birdfont-export.1", 
"birdfont-import.1", "birdfont-autotrace.1"):
        yield {
            'name': name,
            'file_dep': ['resources/linux/%s' % name],
            'targets': ['build/%s.gz' % name],
            'actions': ["gzip -9 -c %(dependencies)s > %(targets)s"],
            }


def task_distclean ():
    return  {
        'actions': ['rm -rf .doit.db build scripts/config.py scripts/*.pyc dodo.pyc libbirdfont/Config.vala'],
        }

