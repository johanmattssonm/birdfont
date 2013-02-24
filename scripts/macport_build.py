#!/usr/bin/python

import os
import shutil
import subprocess
import sys
from optparse import OptionParser

import configfile

def run(cmd):
	process = subprocess.Popen (cmd, shell=True)
	process.communicate()[0]
	if not process.returncode == 0:
		print("Error: " + cmd)
		exit(1)

def build ():
	#libbirdfont
	run("rm -rf build")
	run("mkdir -p build/libbirdfont")
	run("mkdir -p build/bin")

	run("valac -C --basedir build/libbirdfont/ --enable-experimental-non-null --enable-experimental --define=MAC --library libbirdfont -H build/libbirdfont/birdfont.h libbirdfont/* --pkg libxml-2.0 --pkg gio-2.0  --pkg cairo --pkg libsoup-2.4 --pkg gdk-pixbuf-2.0 --pkg webkit-1.0")
	run("cp libbirdfont/*.c build/libbirdfont/")

	run("""gcc -c build/libbirdfont/*.c -shared -fno-common -fPIC -D 'GETTEXT_PACKAGE="birdfont"' $(pkg-config --cflags --libs libxml-2.0) $(pkg-config --cflags --libs gio-2.0) $(pkg-config --cflags --libs cairo) $(pkg-config --cflags --libs glib-2.0) $(pkg-config --cflags --libs gdk-pixbuf-2.0) $(pkg-config --cflags --libs webkit-1.0) -I ./build/mac/birdfont""")
	run("mv ./*.o build/libbirdfont/ ")

	run("gcc -dynamiclib -Wl,-headerpad_max_install_names,-undefined,dynamic_lookup,-compatibility_version,1.0,-current_version,1.0,-install_name,/usr/local/lib/libbirdfont.dylib -shared build/libbirdfont/*.o $(pkg-config --cflags --libs libxml-2.0) $(pkg-config --cflags --libs gio-2.0) $(pkg-config --cflags --libs cairo) $(pkg-config --cflags --libs glib-2.0) $(pkg-config --cflags --libs gdk-pixbuf-2.0) $(pkg-config --cflags --libs webkit-1.0) -shared -o libbirdfont.dylib")
	run("mv libbirdfont.dylib build/bin/")

	# birdfont
	run("mkdir -p build/birdfont")
	
	run("valac -C --enable-experimental-non-null --enable-experimental --define=MAC birdfont/* --vapidir=./ --pkg libxml-2.0 --pkg gio-2.0  --pkg cairo --pkg libsoup-2.4 --pkg gdk-pixbuf-2.0 --pkg webkit-1.0 --pkg gtk+-2.0 --pkg libbirdfont")
	run("mv birdfont/*.c build/birdfont/")

	run("""gcc -c ./build/libbirdfont/birdfont.h build/birdfont/*.c -D 'GETTEXT_PACKAGE="birdfont"' $(pkg-config --cflags libxml-2.0) $(pkg-config --cflags gio-2.0) $(pkg-config --cflags cairo) $(pkg-config --cflags glib-2.0) $(pkg-config --cflags gdk-pixbuf-2.0) $(pkg-config --cflags webkit-1.0) -I ./build/libbirdfont/""")
	run("mv ./*.o build/birdfont/")

	run("gcc build/birdfont/*.o ./build/bin/libbirdfont.dylib $(pkg-config --cflags --libs libxml-2.0) $(pkg-config --cflags --libs gio-2.0) $(pkg-config --cflags --libs cairo) $(pkg-config --cflags --libs glib-2.0) $(pkg-config --cflags --libs gdk-pixbuf-2.0) $(pkg-config --cflags --libs webkit-1.0) $(pkg-config --cflags --libs gtk+-2.0) -o ./build/bin/birdfont")

	# birdfont-export
	run("mkdir -p build/birdfont-export")
	
	run("valac -C --enable-experimental-non-null --enable-experimental --define=MAC birdfont-export/* --vapidir=./ --pkg libxml-2.0 --pkg gio-2.0  --pkg cairo --pkg libsoup-2.4 --pkg gdk-pixbuf-2.0 --pkg webkit-1.0 --pkg gtk+-2.0 --pkg libbirdfont")
	run("mv birdfont-export/*.c build/birdfont-export/")

	run("""gcc -c ./build/libbirdfont/birdfont.h build/birdfont-export/*.c -D 'GETTEXT_PACKAGE="birdfont"' $(pkg-config --cflags libxml-2.0) $(pkg-config --cflags gio-2.0) $(pkg-config --cflags cairo) $(pkg-config --cflags glib-2.0) $(pkg-config --cflags gdk-pixbuf-2.0) $(pkg-config --cflags webkit-1.0) -I ./build/libbirdfont/""")
	run("mv ./*.o build/birdfont-export/")

	run("gcc build/birdfont-export/*.o ./build/bin/libbirdfont.dylib $(pkg-config --cflags --libs libxml-2.0) $(pkg-config --cflags --libs gio-2.0) $(pkg-config --cflags --libs cairo) $(pkg-config --cflags --libs glib-2.0) $(pkg-config --cflags --libs gdk-pixbuf-2.0) $(pkg-config --cflags --libs webkit-1.0) $(pkg-config --cflags --libs gtk+-2.0) -o ./build/bin/birdfont-export")

	run("touch build/installed")
	run("touch build/configured")

	# application launcher
	run("mkdir -p build/BirdFont.app")
	run("mkdir -p build/BirdFont.app/Contents")
	run("mkdir -p build/BirdFont.app/Contents/MacOs")
	run("mkdir -p build/BirdFont.app/Contents/Resources")

	run("cp mac/birdfont.sh build/BirdFont.app/Contents/MacOs")
	run("cp mac/Info.plist build/BirdFont.app/Contents/")	
	run("cp mac/birdfont.icns build/BirdFont.app/Contents/Resources")

build ()


