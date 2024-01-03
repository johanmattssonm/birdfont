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

from scripts import version
from scripts.translations import compile_translations
from scripts import config
from scripts.builder import Builder

DOIT_CONFIG = {
    'default_tasks': [
        'build',
        'compile_translations',
        'man',
        'libbirdfont', 
        'libbirdgems', 
        'birdfont', 
        'birdfont-autotrace',
        'birdfont-export',
        'birdfont-import'
        ],
    }

if "kfreebsd" in sys.platform:
    LIBBIRDGEMS_SO_VERSION=version.LIBBIRDGEMS_SO_VERSION
elif "openbsd" in sys.platform:
    LIBBIRDGEMS_SO_VERSION='${LIBbirdgems_VERSION}'
else:
    LIBBIRDGEMS_SO_VERSION=version.LIBBIRDGEMS_SO_VERSION

if "kfreebsd" in sys.platform:
    SO_VERSION=version.SO_VERSION
elif "openbsd" in sys.platform:
    SO_VERSION='${LIBbirdfont_VERSION}'
else:
    SO_VERSION=version.SO_VERSION

def soname(target_binary):
    if "darwin" in sys.platform or "msys" in sys.platform:
        return ''
        
    return '-Wl,-soname,' + target_binary

def make_birdfont(target_binary, deps):
    valac_command = """{valac} \
        -C \
        --vapidir=./ \
        --basedir build/birdfont/ \
        {non_null} \
        {valacflags[birdfont]} \
        --enable-experimental \
        birdfont/*.vala \
		--vapidir=./ \
		--pkg {gee} \
		--pkg gio-2.0  \
		--pkg cairo \
		--pkg gdk-pixbuf-2.0 \
		--pkg webkit2gtk-4.1 \
		--pkg libnotify \
		--pkg xmlbird \
		--pkg libbirdfont \
        """.format(**config.SETTINGS)
        
    cc_command = """{cc} {cflags[birdfont]} \
        -c C_SOURCE \
		-D 'GETTEXT_PACKAGE="birdfont"' \
        -I./build/libbirdfont \
		$({pkg-config} --cflags sqlite3) \
		$({pkg-config} --cflags {gee}) \
		$({pkg-config} --cflags gio-2.0) \
		$({pkg-config} --cflags cairo) \
		$({pkg-config} --cflags glib-2.0) \
		$({pkg-config} --cflags gdk-pixbuf-2.0) \
		$({pkg-config} --cflags xmlbird) \
		$({pkg-config} --cflags webkit2gtk-4.1) \
		$({pkg-config} --cflags libnotify) \
        -o OBJECT_FILE""".format(**config.SETTINGS)
        
    linker_command = """{cc} {ldflags[birdfont]} \
        build/birdfont/*.o \
		-L./build/bin -lbirdfont \
		$({pkg-config} --libs sqlite3) \
		$({pkg-config} --libs {gee}) \
		$({pkg-config} --libs gio-2.0) \
		$({pkg-config} --libs cairo) \
		$({pkg-config} --libs cairo-gobject) \
		$({pkg-config} --libs glib-2.0) \
		$({pkg-config} --libs gdk-pixbuf-2.0) \
		$({pkg-config} --libs webkit2gtk-4.1) \
		$({pkg-config} --libs xmlbird) \
		$({pkg-config} --libs libnotify) \
		-L./build -L./build/bin -l birdgems \
        -o build/bin/""".format(**config.SETTINGS) + target_binary

    birdfont = Builder('birdfont',
                          valac_command, 
                          cc_command,
                          linker_command,
                          target_binary,
                          None,
                          deps)
			
    yield birdfont.build()

def task_birdfont():
    yield make_birdfont('birdfont', ['libbirdgems.so', 'libbirdfont.so'])

def make_birdfont_export(target_binary, deps):
    valac_command = """{valac} \
        -C \
		--enable-experimental \
        --basedir build/birdfont-export/ \
        {non_null} \
        {valacflags[birdfont-export]} \
		birdfont-export/*.vala \
		--vapidir=./ \
		--pkg {gee} \
		--pkg gio-2.0  \
		--pkg cairo \
		--pkg xmlbird \
		--pkg libbirdfont \
        """.format(**config.SETTINGS)

    cc_command = """{cc} {cflags[birdfont-export]} \
        -c C_SOURCE \
		-D 'GETTEXT_PACKAGE="birdfont"' \
        -I./build/libbirdfont \
		$({pkg-config} --cflags sqlite3) \
		$({pkg-config} --cflags {gee}) \
		$({pkg-config} --cflags gio-2.0) \
		$({pkg-config} --cflags cairo) \
		$({pkg-config} --cflags glib-2.0) \
		$({pkg-config} --cflags xmlbird) \
        -o OBJECT_FILE""".format(**config.SETTINGS)
        
    linker_command = """{cc} {ldflags[birdfont-export]} \
		build/birdfont-export/*.o \
		-Lbuild/bin/ -lbirdfont \
		-lm \
		$({pkg-config} --libs sqlite3) \
		$({pkg-config} --libs {gee}) \
		$({pkg-config} --libs gio-2.0) \
		$({pkg-config} --libs cairo) \
		$({pkg-config} --libs cairo-gobject) \
		$({pkg-config} --libs glib-2.0) \
		$({pkg-config} --libs xmlbird) \
		-L./build -L./build/bin -l birdgems \
		-o ./build/bin/""".format(**config.SETTINGS) + target_binary

    birdfont_export = Builder('birdfont-export',
                              valac_command, 
                              cc_command,
                              linker_command,
                              target_binary,
                              None,
                              deps)
			
    yield birdfont_export.build()

def task_birdfont_export():
    yield make_birdfont_export('birdfont-export', ['libbirdgems.so', 'libbirdfont.so'])

def make_birdfont_import(target_binary, deps):
    valac_command = """{valac} \
        -C  \
		--enable-experimental \
        --basedir build/birdfont-import/ \
        {non_null} \
        {valacflags[birdfont-import]} \
		birdfont-import/*.vala \
		--vapidir=./ \
		 loadfont.vapi \
		--pkg {gee} \
		--pkg gio-2.0  \
		--pkg cairo \
		--pkg xmlbird \
		--pkg libbirdfont \
        """.format(**config.SETTINGS)
        
    cc_command = """{cc} {cflags[birdfont-import]} \
        -c C_SOURCE \
		-D 'GETTEXT_PACKAGE="birdfont"' \
        -I./build/libbirdfont \
		$({pkg-config} --cflags sqlite3) \
		$({pkg-config} --cflags {gee}) \
		$({pkg-config} --cflags gio-2.0) \
		$({pkg-config} --cflags cairo) \
		$({pkg-config} --libs cairo-gobject) \
		$({pkg-config} --cflags glib-2.0) \
		$({pkg-config} --cflags xmlbird) \
        -o OBJECT_FILE""".format(**config.SETTINGS)

    linker_command = """{cc} {ldflags[birdfont-import]} \
		build/birdfont-import/*.o \
		-Lbuild/bin/ -lbirdfont \
		-lm \
		$({pkg-config} --libs sqlite3) \
		$({pkg-config} --libs {gee}) \
		$({pkg-config} --libs gio-2.0) \
		$({pkg-config} --libs cairo) \
		$({pkg-config} --libs cairo-gobject) \
		$({pkg-config} --libs glib-2.0) \
		$({pkg-config} --libs xmlbird) \
		-L./build -L./build/bin -l birdgems \
		-o ./build/bin/""".format(**config.SETTINGS) + target_binary

    birdfont_import = Builder('birdfont-import',
                          valac_command, 
                          cc_command,
                          linker_command,
                          target_binary,
                          None,
                          deps)
			
    yield birdfont_import.build()

def task_birdfont_import():
    yield make_birdfont_import('birdfont-import', ['libbirdgems.so', 'libbirdfont.so'])
	
def make_birdfont_autotrace(target_binary, deps):
    valac_command = """{valac} \
        -C \
		--enable-experimental \
        --basedir build/birdfont-autotrace/ \
        {non_null} \
        {valacflags[birdfont-autotrace]} \
		birdfont-autotrace/*.vala \
		--vapidir=./ \
		--pkg {gee} \
		--pkg gio-2.0  \
		--pkg cairo \
		--pkg xmlbird \
		--pkg libbirdfont \
        """.format(**config.SETTINGS)
        
    cc_command = """{cc} {cflags[birdfont-autotrace]} \
        -c C_SOURCE \
		-D 'GETTEXT_PACKAGE="birdfont"' \
        -I./build/libbirdfont \
		$({pkg-config} --cflags sqlite3) \
		$({pkg-config} --cflags {gee}) \
		$({pkg-config} --cflags gio-2.0) \
		$({pkg-config} --cflags cairo) \
		$({pkg-config} --cflags glib-2.0) \
		$({pkg-config} --cflags xmlbird) \
        -o OBJECT_FILE""".format(**config.SETTINGS)
        
    linker_command = """{cc} {ldflags[birdfont-autotrace]} \
		build/birdfont-autotrace/*.o \
        -I./build/libbirdfont \
		-Lbuild/bin/ -lbirdfont \
		-lm \
		$({pkg-config} --libs sqlite3) \
		$({pkg-config} --libs {gee}) \
		$({pkg-config} --libs gio-2.0) \
		$({pkg-config} --libs cairo) \
		$({pkg-config} --libs cairo-gobject) \
		$({pkg-config} --libs glib-2.0) \
		$({pkg-config} --libs xmlbird) \
		-L./build -L./build/bin -l birdgems \
		-o ./build/bin/""".format(**config.SETTINGS) + target_binary

    birdfont_autotrace = Builder('birdfont-autotrace',
                          valac_command, 
                          cc_command,
                          linker_command,
                          target_binary,
                          None,
                          deps)
			
    yield birdfont_autotrace.build()

def task_birdfont_autotrace():
    yield make_birdfont_autotrace('birdfont-autotrace', ['libbirdgems.so', 'libbirdfont.so'])
    
def make_libbirdfont(target_binary, deps):	
    valac_command = config.VALAC + """\
        -C \
        --vapidir=./ \
        --basedir build/libbirdfont/ \
        """ + config.NON_NULL + """ \
        """ + config.VALACFLAGS.get("libbirdfont", "") + """ \
        --enable-experimental \
        --library libbirdfont \
        -H build/libbirdfont/birdfont.h \
        libbirdfont/*.vala \
        libbirdfont/OpenFontFormat/*.vala \
        libbirdfont/Renderer/*.vala \
        loadfont.vapi \
        --pkg posix \
        --pkg """ + config.GEE + """ \
        --pkg gio-2.0 \
        --pkg cairo \
        --pkg xmlbird \
        --pkg libbirdgems \
        --pkg sqlite3 \
        --pkg gdk-pixbuf-2.0 \
        """
        
    cc_command = """{cc} {cflags[libbirdfont]} \
            -c C_SOURCE \
            -fPIC \
            -D 'GETTEXT_PACKAGE="birdfont"' \
            -I ./build/libbirdfont \
            -I ./build/libbirdgems \
            $({pkg-config} --cflags sqlite3) \
            $({pkg-config} --cflags fontconfig) \
            $({pkg-config} --cflags {gee}) \
            $({pkg-config} --cflags gio-2.0) \
            $({pkg-config} --cflags cairo) \
            $({pkg-config} --cflags glib-2.0) \
            $({pkg-config} --cflags xmlbird) \
            -o OBJECT_FILE""".format(**config.SETTINGS)

    linker_command = ("""{cc} {ldflags[libbirdfont]} \
            -shared \
            """ + soname(target_binary) + """ \
            build/libbirdfont/*.o \
            $({pkg-config} --libs sqlite3) \
            $(freetype-config --libs) \
            $({pkg-config} --libs {gee}) \
            $({pkg-config} --libs gio-2.0) \
            $({pkg-config} --libs fontconfig) \
            $({pkg-config} --libs cairo) \
            $({pkg-config} --libs cairo-gobject) \
            $({pkg-config} --libs glib-2.0) \
            $({pkg-config} --libs xmlbird) \
            -L./build -L./build/bin -l birdgems \
            -o ./build/bin/""").format(**config.SETTINGS) + target_binary

    libbirdfont = Builder('libbirdfont',
                          valac_command, 
                          cc_command,
                          linker_command,
                          target_binary,
                          'libbirdfont.so',
                          deps)
			
    yield libbirdfont.build()

def task_libbirdfont():
    yield make_libbirdfont('libbirdfont.so.' + SO_VERSION, ['libbirdgems.so'])


def make_libbirdgems(target_binary, deps):
    valac_command = """{valac} \
		-C \
		-H build/libbirdgems/birdgems.h \
		--pkg posix \
		--vapidir=./ \
		--basedir=build/libbirdgems/ \
		{non_null} \
        {valacflags[libbirdgems]} \
		--enable-experimental \
		--library libbirdgems \
		libbirdgems/*.vala \
        """.format(**config.SETTINGS)

    cc_command = """{cc} {cflags[libbirdgems]} \
			-fPIC \
			$({pkg-config} --cflags glib-2.0) \
			-c C_SOURCE \
            -o OBJECT_FILE \
			""".format(**config.SETTINGS)

    linker_command = ("""{cc} {ldflags[libbirdgems]} \
			-shared \
			""" + soname(target_binary) + """ \
			-fPIC \
			build/libbirdgems/*.o \
			$({pkg-config} --libs glib-2.0) \
			$({pkg-config} --libs gobject-2.0) \
			-o build/bin/""").format(**config.SETTINGS) + target_binary

    libbirdgems = Builder('libbirdgems',
                          valac_command, 
                          cc_command,
                          linker_command,
                          target_binary,
						  'libbirdgems.so',
                          deps)
			
    yield libbirdgems.build()

def task_libbirdgems():
    yield make_libbirdgems('libbirdgems.so.' + LIBBIRDGEMS_SO_VERSION, []) 

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
            'file_dep': ['resources/linux/' + name],
            'targets': ['build/' + name + '.gz'],
            'actions': ['gzip -9 -c resources/linux/' + name + ' > ' + 'build/' + name + '.gz'],
            }

def task_distclean ():
    return  {
        'actions': ['rm -rf .doit.db build scripts/config.py'
                    + ' libbirdfont/Config.vala'
                    + ' __pycache__ scripts/__pycache__']
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
