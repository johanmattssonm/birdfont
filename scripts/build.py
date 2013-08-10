#!/usr/bin/python
"""
Copyright (C) 2013 Johan Mattsson

This library is free software; you can redistribute it and/or modify 
it under the terms of the GNU Lesser General Public License as 
published by the Free Software Foundation; either version 3 of the 
License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but 
WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
Lesser General Public License for more details.
"""

import os
import shutil
import subprocess
import sys
from optparse import OptionParser
from run import run

import configfile

def libbirdfont(prefix, cc, cflags, ldflags, valac, valaflags, library):
	#libbirdfont
	run("mkdir -p build/libbirdfont")
	run("mkdir -p build/bin")

	run(valac + """\
		-C \
		""" + valaflags + """ \
		--basedir build/libbirdfont/ \
		--enable-experimental-non-null \
		--enable-experimental \
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
		-D 'GETTEXT_PACKAGE="birdfont"' \
		$(pkg-config --cflags libxml-2.0) \
		$(pkg-config --cflags gio-2.0) \
		$(pkg-config --cflags cairo) \
		$(pkg-config --cflags glib-2.0) \
		$(pkg-config --cflags gdk-pixbuf-2.0) \
		-I ./build/mac/birdfont""")
	run("mv ./*.o build/libbirdfont/ ")

	run(cc + " " + ldflags + """ \
		-shared \
		build/libbirdfont/*.o \
		$(freetype-config --libs) \
		$(pkg-config --libs libxml-2.0) \
		$(pkg-config --libs gio-2.0) \
		$(pkg-config --libs cairo) \
		$(pkg-config --libs glib-2.0) \
		$(pkg-config --libs gdk-pixbuf-2.0) \
		-o """ + library)
	run("mv " + library + " build/bin/")

def birdfont_export(prefix, cc, cflags, ldflags, valac, valaflags, library):
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
		-L build/bin/ -l""" + library + """ \
		$(pkg-config --libs libxml-2.0) \
		$(pkg-config --libs gio-2.0) \
		$(pkg-config --libs cairo) \
		$(pkg-config --libs glib-2.0) \
		$(pkg-config --libs gdk-pixbuf-2.0) \
		-o ./build/bin/birdfont-export""")

	run("touch build/installed")
	run("touch build/configured")
	
def birdfont_gtk(prefix, cc, cflags, ldflags, valac, valaflags, library):
	# birdfont
	run("mkdir -p build/birdfont")
	
	run(valac + " " + valaflags  + """\
		-C \
		birdfont/* \
		--enable-experimental-non-null \
		--enable-experimental \
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
		build/birdfont/*.o \
		-L build/bin/ -l""" + library + """ \
		$(pkg-config --libs libxml-2.0) \
		$(pkg-config --libs gio-2.0) \
		$(pkg-config --libs cairo) \
		$(pkg-config --libs glib-2.0) \
		$(pkg-config --libs gdk-pixbuf-2.0) \
		$(pkg-config --libs webkit-1.0) \
		$(pkg-config --libs gtk+-2.0) \
		-o ./build/bin/birdfont""")

