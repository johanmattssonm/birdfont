#!/usr/bin/python
"""
Copyright (C) 2013 Johan Mattsson

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
import shutil
import subprocess
import sys
from optparse import OptionParser
from translations import compile_translations
from run import run

import configfile

def build(prefix, cc, cflags, ldflags, valac):
	compile_translations ()
	
	#libbirdfont
	run("mkdir -p build/libbirdfont")
	run("mkdir -p build/bin")

	run(valac + """\
		-C \
		--basedir build/libbirdfont/ \
		--enable-experimental-non-null \
		--enable-experimental \
		--define=MAC \
		--library libbirdfont \
		-H build/libbirdfont/birdfont.h \
		libbirdfont/*.vala \
		libbirdfont/OpenFontFormat/*.vala \
		--pkg libxml-2.0 \
		--pkg gio-2.0 \
		--pkg cairo \
		--pkg libsoup-2.4 \
		--pkg gdk-pixbuf-2.0""")

	#copy c sources 
	run("cp libbirdfont/OpenFontFormat/*.c build/libbirdfont/")

	run(cc + " " + cflags + """ \
		-c build/libbirdfont/*.c \
		-fno-common \
		-fPIC \
		-D 'GETTEXT_PACKAGE="birdfont"' \
		$(pkg-config --cflags libxml-2.0) \
		$(pkg-config --cflags gio-2.0) \
		$(pkg-config --cflags cairo) \
		$(pkg-config --cflags glib-2.0) \
		$(pkg-config --cflags gdk-pixbuf-2.0) \
		-I ./build/mac/birdfont""")
	run("mv ./*.o build/libbirdfont/ ")

	run(cc + " " + ldflags + """ \
		-dynamiclib -Wl,-headerpad_max_install_names,-undefined,dynamic_lookup,-compatibility_version,1.0,-current_version,1.0,-install_name,""" + prefix + """/lib/libbirdfont.dylib -shared build/libbirdfont/*.o \
		 $(pkg-config --libs libxml-2.0) \
		 $(pkg-config --libs gio-2.0) \
		 $(pkg-config --libs cairo) \
		 $(pkg-config --libs glib-2.0) \
		 $(pkg-config --libs gdk-pixbuf-2.0) \
		 -shared -o libbirdfont.dylib""")
	run("mv libbirdfont.dylib build/bin/")

	# birdfont
	run("mkdir -p build/birdfont")
	
	run(valac + """\
		-C \
		--enable-experimental-non-null \
		--enable-experimental \
		--define=MAC birdfont/* \
		--vapidir=./ \
		--pkg libxml-2.0 \
		--pkg gio-2.0  \
		--pkg cairo \
		--pkg libsoup-2.4 \
		--pkg gdk-pixbuf-2.0 \
		--pkg webkit-1.0 \
		--pkg gtk+-2.0\
		--pkg libbirdfont""")
	run("mv birdfont/*.c build/birdfont/")

	run(cc + " " + cflags + """\
		-c ./build/libbirdfont/birdfont.h build/birdfont/*.c \
		-D 'GETTEXT_PACKAGE="birdfont"' \
		$(pkg-config --cflags libxml-2.0) \
		$(pkg-config --cflags gio-2.0) \
		$(pkg-config --cflags cairo) \
		$(pkg-config --cflags glib-2.0) \
		$(pkg-config --cflags gdk-pixbuf-2.0) \
		$(pkg-config --cflags webkit-1.0) \
		-I ./build/libbirdfont/""")
	run("mv ./*.o build/birdfont/")

	run(cc + " " + ldflags + """ \
		build/birdfont/*.o ./build/bin/libbirdfont.dylib \
		$(pkg-config --libs libxml-2.0) \
		$(pkg-config --libs gio-2.0) \
		$(pkg-config --libs cairo) \
		$(pkg-config --libs glib-2.0) \
		$(pkg-config --libs gdk-pixbuf-2.0) \
		$(pkg-config --libs webkit-1.0) \
		$(pkg-config --libs gtk+-2.0) \
		-o ./build/bin/birdfont""")

	# birdfont-export
	run("mkdir -p build/birdfont-export")
	
	run(valac + """ \
		-C \
		--enable-experimental-non-null \
		--enable-experimental \
		--define=MAC birdfont-export/* \
		--vapidir=./ \
		--pkg libxml-2.0 \
		--pkg gio-2.0  \
		--pkg cairo \
		--pkg gdk-pixbuf-2.0 \
		--pkg gtk+-2.0 \
		--pkg libbirdfont""")
	run("mv birdfont-export/*.c build/birdfont-export/")

	run(cc + " " + cflags + """ \
		-c ./build/libbirdfont/birdfont.h build/birdfont-export/*.c \
		-D 'GETTEXT_PACKAGE="birdfont"' \
		$(pkg-config --cflags libxml-2.0) \
		$(pkg-config --cflags gio-2.0) \
		$(pkg-config --cflags cairo) \
		$(pkg-config --cflags glib-2.0) \
		$(pkg-config --cflags gdk-pixbuf-2.0) \
		-I ./build/libbirdfont/""")
	run("mv ./*.o build/birdfont-export/")

	run(cc + " " + ldflags + " \
		build/birdfont-export/*.o \
		./build/bin/libbirdfont.dylib \
		$(pkg-config --libs libxml-2.0) \
		$(pkg-config --libs gio-2.0) \
		$(pkg-config --libs cairo) \
		$(pkg-config --libs glib-2.0) \
		$(pkg-config --libs gdk-pixbuf-2.0) \
		-o ./build/bin/birdfont-export")

	run("touch build/installed")
	run("touch build/configured")
	

def build_app (prefix):
	# application launcher
	run("mkdir -p build/BirdFont.app")
	run("mkdir -p build/BirdFont.app/Contents")
	run("mkdir -p build/BirdFont.app/Contents/MacOS")
	run("mkdir -p build/BirdFont.app/Contents/Resources")
	
	startup = open ('build/BirdFont.app/Contents/MacOS/birdfont.sh', 'w+')
	startup.write ("#!/bin/bash\n")
	startup.write (prefix + "/bin/birdfont\n")
	
	run("chmod 755 build/BirdFont.app/Contents/MacOS/birdfont.sh")
	
	run("cp -R -p resources/mac/Info.plist build/BirdFont.app/Contents/")	
	run("cp -R -p resources/mac/birdfont.icns build/BirdFont.app/Contents/Resources")

parser = OptionParser()
parser.add_option("-p", "--prefix", dest="prefix", help="install prefix", metavar="PREFIX")
parser.add_option("-d", "--dest", dest="dest", help="install to this directory", metavar="DEST")
parser.add_option("-c", "--cc", dest="cc", help="select the C compiler", metavar="CC")
parser.add_option("-f", "--cflags", dest="cflags", help="set compiler flags", metavar="CFLAGS")
parser.add_option("-l", "--ldflags", dest="ldflags", help="set linker flags", metavar="LDFLAGS")
parser.add_option("-v", "--valac", dest="valac", help="select vala compiler", metavar="VALAC")

(options, args) = parser.parse_args()

if not options.prefix:
	options.prefix = "/opt/local"
if not options.cc:
	options.cc = "gcc"
if not options.cflags:
	options.cflags = ""
if not options.ldflags:
	options.ldflags = ""
if not options.valac:
	options.valac = "valac"

build_app (options.prefix)	
build (options.prefix, options.cc, options.cflags, options.ldflags, options.valac)



