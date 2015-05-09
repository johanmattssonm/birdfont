#!/usr/bin/python
"""
Copyright (C) 2013, 2014 2015 Johan Mattsson

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
import version
from optparse import OptionParser
from run import run

import config

def libbirdfont(prefix, cc, cflags, ldflags, valac, valaflags, library, nonNull = True, usePixbuf = True):
	#libbirdfont
	run("mkdir -p build/libbirdfont")
	run("mkdir -p build/bin")

	experimentalNonNull = ""
	if nonNull:
		experimentalNonNull = "--enable-experimental-non-null"

	run(valac + """\
		-C \
		""" + valaflags + """ \
		--vapidir=./ \
		--basedir build/libbirdfont/ \
		""" + experimentalNonNull + """ \
		--enable-experimental \
		--library libbirdfont \
		-H build/libbirdfont/birdfont.h \
		libbirdfont/*.vala \
		libbirdfont/OpenFontFormat/*.vala \
		libbirdfont/Renderer/*.vala \
		--pkg """ + config.GEE + """ \
		--pkg gio-2.0 \
		--pkg cairo \
		--pkg libbirdxml \
		--pkg libbirdgems \
		""")
	
	#copy c sources 
	run("cp libbirdfont/OpenFontFormat/*.c build/libbirdfont/")

	if cc == "":
		print ("Skipping compilation");
	else:
		run(cc + " " + cflags + """ \
			-c build/libbirdfont/*.c \
			-fPIC \
			-D 'GETTEXT_PACKAGE="birdfont"' \
			$(pkg-config --cflags """ + config.GEE + """) \
			$(pkg-config --cflags gio-2.0) \
			$(pkg-config --cflags cairo) \
			$(pkg-config --cflags glib-2.0) \
			-I ./build/libbirdxml \
			-I ./build/libbirdgems""")
		run("mv ./*.o build/libbirdfont/ ")

		if library.endswith (".dylib"):
			sonameparam = "" # gcc on mac os does not have the soname parameter
		else:
			sonameparam = "-Wl,-soname," + library
		
		run(cc + " " + ldflags + """ \
			-shared \
			""" + sonameparam + """ \
			build/libbirdfont/*.o \
			$(freetype-config --libs) \
			$(pkg-config --libs """ + config.GEE + """) \
			$(pkg-config --libs gio-2.0) \
			$(pkg-config --libs cairo) \
			$(pkg-config --libs glib-2.0) \
			-L./build -L./build/bin -l birdxml -l birdgems\
			-o """ + library)
		run("mv " + library + " build/bin/")
		
		if os.path.exists("build/bin/libbirdfont.so"):
			run ("cd build/bin && unlink libbirdfont.so")

		# create link to the versioned library
		if library.find ('.so') > -1:
			run ("""cd build/bin && ln -sf """ + library + " libbirdfont.so")
		elif library.find ('.dylib') > -1:
			run ("""cd build/bin && ln -sf """ + library + " libbirdfont.dylib")

		run("rm -f build/birdfont.1.gz")
		run("cp resources/linux/birdfont.1 build/")
		run("gzip build/birdfont.1")	

		run("rm -f build/birdfont-export.1.gz")	
		run("cp resources/linux/birdfont-export.1 build/")
		run("gzip build/birdfont-export.1")

		run("rm -f build/birdfont-import.1.gz")	
		run("cp resources/linux/birdfont-import.1 build/")
		run("gzip build/birdfont-import.1")
 				

def libbirdxml(prefix, cc, cflags, ldflags, valac, valaflags, library, nonNull = True):
	#libbirdfont
	run("mkdir -p build/libbirdxml")
	run("mkdir -p build/bin")

	experimentalNonNull = ""
	if nonNull:
		experimentalNonNull = "--enable-experimental-non-null"

	run(valac + """\
		-C \
		""" + valaflags + """ \
		--pkg posix \
		--vapidir=./ \
		--basedir build/libbirdxml/ \
		""" + experimentalNonNull + """ \
		--enable-experimental \
		--library libbirdxml \
		-H build/libbirdxml/birdxml.h \
		libbirdxml/*.vala \
		""")
	
	if cc == "":
		print ("Skipping compilation");
	else:
		run(cc + " " + cflags + """ \
			-c build/libbirdxml/*.c \
			-fPIC \
			$(pkg-config --cflags glib-2.0) \
			$(pkg-config --cflags gobject-2.0) \
			""")
			
		run("mv ./*.o build/libbirdxml/ ")

		if library.endswith (".dylib"):
			sonameparam = "" # gcc on mac os does not have the soname parameter
		else:
			sonameparam = "-Wl,-soname," + library
		
		run(cc + " " + ldflags + """ \
			-shared \
			""" + sonameparam + """ \
			build/libbirdxml/*.o \
			$(pkg-config --libs glib-2.0) \
			$(pkg-config --libs gobject-2.0) \
			-o """ + library)
		run("mv " + library + " build/bin/")
		
		if os.path.exists("build/bin/libbirdxml.so"):
			run ("cd build/bin && unlink libbirdxml.so")

		# create link to the versioned library
		if library.find ('.so') > -1:
			run ("""cd build/bin && ln -sf """ + library + " libbirdxml.so")
		elif library.find ('.dylib') > -1:
			run ("""cd build/bin && ln -sf """ + library + " libbirdxml.dylib")
 		

def libbirdgems(prefix, cc, cflags, ldflags, valac, valaflags, library, nonNull = True):
	print ('Compiling libbirdgems')
	run("mkdir -p build/libbirdgems")
	run("mkdir -p build/bin")

	experimentalNonNull = ""
	if nonNull:
		experimentalNonNull = "--enable-experimental-non-null"

	run(valac + """\
		-C \
		""" + valaflags + """ \
		-H build/libbirdgems/birdgems.h \
		--pkg posix \
		--vapidir=./ \
		--basedir build/libbirdgems/ \
		""" + experimentalNonNull + """ \
		--enable-experimental \
		--library libbirdgems \
		libbirdgems/*.vala \
		""")
	
	if cc == "":
		print ("Skipping compilation");
	else:
		run("cp libbirdgems/*.c build/libbirdgems/")
		run("cp libbirdgems/*.h build/libbirdgems/")
			
		run(cc + " " + cflags + """ \
			$(pkg-config --cflags glib-2.0) \
			-c build/libbirdgems/*.c \
			""")
			
		run("mv ./*.o build/libbirdgems/ ")

		if library.endswith (".dylib"):
			sonameparam = "" # gcc on mac os does not have the soname parameter
		else:
			sonameparam = "-Wl,-soname," + library
		
		run(cc + " " + ldflags + """ \
			-shared \
			""" + sonameparam + """ \
			build/libbirdgems/*.o \
			$(pkg-config --libs glib-2.0) \
			$(pkg-config --libs gobject-2.0) \
			-o """ + library)
		run("mv " + library + " build/bin/")
		
		if os.path.exists("build/bin/libbirdgems.so"):
			run ("cd build/bin && unlink libbirdgems.so")

		# create link to the versioned library
		if library.find ('.so') > -1:
			run ("""cd build/bin && ln -sf """ + library + " libbirdgems.so")
		elif library.find ('.dylib') > -1:
			run ("""cd build/bin && ln -sf """ + library + " libbirdgems.dylib")

	
def birdfont_export(prefix, cc, cflags, ldflags, valac, valaflags, nonNull = True):
	# birdfont-export
	run("mkdir -p build/birdfont-export")

	experimentalNonNull = ""
	if nonNull:
		experimentalNonNull = "--enable-experimental-non-null"
			
	run(valac + """ \
		-C \
		""" + valaflags + """ \
		""" + experimentalNonNull + """ \
		--enable-experimental \
		--define=MAC \
		birdfont-export/*.vala \
		--vapidir=./ \
		--pkg """ + config.GEE + """ \
		--pkg gio-2.0  \
		--pkg cairo \
		--pkg libbirdfont""")
	run("mv birdfont-export/*.c build/birdfont-export/")

	run(cc + " " + cflags + """ \
		-c ./build/libbirdfont/birdfont.h build/birdfont-export/*.c \
		-D 'GETTEXT_PACKAGE="birdfont"' \
		$(pkg-config --cflags """ + config.GEE + """) \
		$(pkg-config --cflags gio-2.0) \
		$(pkg-config --cflags cairo) \
		$(pkg-config --cflags glib-2.0) \
		-I ./build/libbirdfont/""")
	run("mv ./*.o build/birdfont-export/")

	run(cc + " " + ldflags + " \
		build/birdfont-export/*.o \
		-Lbuild/bin/ -lbirdfont \
		-lm \
		$(pkg-config --libs """ + config.GEE + """) \
		$(pkg-config --libs gio-2.0) \
		$(pkg-config --libs cairo) \
		$(pkg-config --libs glib-2.0) \
		-L./build -L./build/bin -l birdxml \
		-o ./build/bin/birdfont-export""")

	run("rm -f build/birdfont.1.gz")
	run("cp resources/linux/birdfont.1 build/")
	run("gzip -9 build/birdfont.1")

	run("rm -f build/birdfont-autotrace.1.gz")	
	run("cp resources/linux/birdfont-autotrace.1 build/")
	run("gzip -9 build/birdfont-autotrace.1")

	run("rm -f build/birdfont-export.1.gz")	
	run("cp resources/linux/birdfont-export.1 build/")
	run("gzip -9 build/birdfont-export.1")
	
	run("touch build/installed")
	run("touch build/configured")

def birdfont_import(prefix, cc, cflags, ldflags, valac, valaflags, nonNull = True):
	# birdfont-import
	run("mkdir -p build/birdfont-import")

	experimentalNonNull = ""
	if nonNull:
		experimentalNonNull = "--enable-experimental-non-null"
			
	run(valac + """ \
		-C \
		""" + valaflags + """ \
		""" + experimentalNonNull + """ \
		--enable-experimental \
		--define=MAC birdfont-import/*.vala \
		--vapidir=./ \
		--pkg """ + config.GEE + """ \
		--pkg gio-2.0  \
		--pkg cairo \
		--pkg libbirdfont""")
	run("mv birdfont-import/*.c build/birdfont-import/")

	run(cc + " " + cflags + """ \
		-c ./build/libbirdfont/birdfont.h build/birdfont-import/*.c \
		-D 'GETTEXT_PACKAGE="birdfont"' \
		$(pkg-config --cflags """ + config.GEE + """) \
		$(pkg-config --cflags gio-2.0) \
		$(pkg-config --cflags cairo) \
		$(pkg-config --cflags glib-2.0) \
		-I ./build/libbirdfont/""")
	run("mv ./*.o build/birdfont-import/")

	run(cc + " " + ldflags + " \
		build/birdfont-import/*.o \
		-Lbuild/bin/ -lbirdfont \
		-lm \
		$(pkg-config --libs """ + config.GEE + """) \
		$(pkg-config --libs gio-2.0) \
		$(pkg-config --libs cairo) \
		$(pkg-config --libs glib-2.0) \
                -L./build -L./build/bin -l birdxml \
		-o ./build/bin/birdfont-import""")

def birdfont_autotrace(prefix, cc, cflags, ldflags, valac, valaflags, nonNull = True):
	# birdfont-autotrace
	run("mkdir -p build/birdfont-autotrace")

	experimentalNonNull = ""
	if nonNull:
		experimentalNonNull = "--enable-experimental-non-null"

	run(valac + """ \
		-C \
		""" + experimentalNonNull + """ \
		--enable-experimental \
		--define=MAC \
		birdfont-autotrace/*.vala \
		--vapidir=./ \
		--pkg """ + config.GEE + """ \
		--pkg gio-2.0  \
		--pkg cairo \
		--pkg gdk-pixbuf-2.0 \
		--pkg libbirdfont""")
	run("mv birdfont-autotrace/*.c build/birdfont-autotrace/")

	run(cc + " " + cflags + """ \
		-c ./build/libbirdfont/birdfont.h build/birdfont-autotrace/*.c \
		-D 'GETTEXT_PACKAGE="birdfont"' \
		$(pkg-config --cflags """ + config.GEE + """) \
		$(pkg-config --cflags gio-2.0) \
		$(pkg-config --cflags cairo) \
		$(pkg-config --cflags glib-2.0) \
		$(pkg-config --cflags gdk-pixbuf-2.0) \
		-I ./build/libbirdfont/""")
	run("mv ./*.o build/birdfont-autotrace/")

	run(cc + " " + ldflags + " \
		build/birdfont-autotrace/*.o \
		-Lbuild/bin/ -lbirdfont \
		-lm \
		$(pkg-config --libs """ + config.GEE + """) \
		$(pkg-config --libs gio-2.0) \
		$(pkg-config --libs cairo) \
		$(pkg-config --libs glib-2.0) \
		$(pkg-config --libs gdk-pixbuf-2.0) \
                -L./build -L./build/bin -l birdxml \
		-o ./build/bin/birdfont-autotrace""")


def birdfont_gtk(prefix, cc, cflags, ldflags, valac, valaflags, nonNull = True):
	# birdfont
	run("mkdir -p build/birdfont")

	experimentalNonNull = ""
	if nonNull:
		experimentalNonNull = "--enable-experimental-non-null"
			
	run(valac + " " + valaflags  + """\
		-C \
		birdfont/*.vala \
		""" + experimentalNonNull + """ \
		--enable-experimental \
		--vapidir=./ \
		--pkg """ + config.GEE + """ \
		--pkg gio-2.0  \
		--pkg cairo \
		--pkg libsoup-2.4 \
		--pkg gdk-pixbuf-2.0 \
		--pkg webkitgtk-3.0 \
		--pkg libnotify\
		--pkg libbirdfont""")
	run("mv birdfont/*.c build/birdfont/")

	run(cc + " " + cflags + """\
		-c ./build/libbirdfont/birdfont.h build/birdfont/*.c \
		-D 'GETTEXT_PACKAGE="birdfont"' \
		$(pkg-config --cflags """ + config.GEE + """) \
		$(pkg-config --cflags gio-2.0) \
		$(pkg-config --cflags cairo) \
		$(pkg-config --cflags glib-2.0) \
		$(pkg-config --cflags gdk-pixbuf-2.0) \
		$(pkg-config --cflags webkitgtk-3.0) \
		$(pkg-config --cflags libnotify) \
		-I ./build/libbirdfont/""")
	run("mv ./*.o build/birdfont/")	

	run(cc + " " + ldflags + """ \
		build/birdfont/*.o \
		-Lbuild/bin/ -lbirdfont \
		$(pkg-config --libs """ + config.GEE + """) \
		$(pkg-config --libs gio-2.0) \
		$(pkg-config --libs cairo) \
		$(pkg-config --libs glib-2.0) \
		$(pkg-config --libs gdk-pixbuf-2.0) \
		$(pkg-config --libs webkitgtk-3.0) \
		$(pkg-config --libs gtk+-2.0) \
		$(pkg-config --libs libnotify) \
                -L./build -L./build/bin -l birdxml \
		-o ./build/bin/birdfont""")

