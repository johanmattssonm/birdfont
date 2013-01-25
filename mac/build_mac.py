#!/usr/bin/python

import os
import shutil
import subprocess
import sys

LOCAL_LIBS = [
	"libxml2.2",
	"libgio-2.0.0",
	"libgobject-2.0.0",
	"libglib-2.0.0",
	"libintl.8",
	"libcairo.2",
	"libgdk_pixbuf-2.0.0",
	"libwebkitgtk-1.0.0",
	"libgtk-x11-2.0.0",
	"libsoup-2.4.1",
	"libjavascriptcoregtk-1.0.0",
	"libgdk-x11-2.0.0",
	"libatk-1.0.0",
	"libpangocairo-1.0.0",
	"libXrender.1",
	"libXinerama.1",
	"libXi.6",
	"libXrandr.2",
	"libXcursor.1",
	"libXcomposite.1",
	"libXdamage.1",
	"libpangoft2-1.0.0",
	"libXfixes.3",
	"libX11.6",
	"libXext.6",
	"libpango-1.0.0",
	"libfreetype.6",
	"libfontconfig.1"
]

def run(cmd):
	process = subprocess.Popen (cmd, shell=True)
	process.communicate()[0]
	if not process.returncode == 0:
		print("Error: " + cmd)
		exit(1)

def build():
	# Compile birdfont on MacOSX 10.5 (Leopard)
	
	#libbirdfont
	run("mkdir -p build/mac/libbirdfont")
	run("mkdir -p build/mac/bin")

	run("valac -C --library libbirdfont -H birdfont.h libbirdfont/* --pkg libxml-2.0 --pkg gio-2.0  --pkg cairo --pkg libsoup-2.4 --pkg gdk-pixbuf-2.0 --pkg webkit-1.0")

	run("mv libbirdfont/*.c build/mac/libbirdfont/ ")
	run("mv ./*.h build/mac/libbirdfont/")

	run("""gcc -c build/mac/libbirdfont/*.c -shared -fno-common -fPIC -D 'GETTEXT_PACKAGE="birdfont"' $(pkg-config --cflags --libs libxml-2.0) $(pkg-config --cflags --libs gio-2.0) $(pkg-config --cflags --libs cairo) $(pkg-config --cflags --libs glib-2.0) $(pkg-config --cflags --libs gdk-pixbuf-2.0) $(pkg-config --cflags --libs webkit-1.0) -I ./build/mac/birdfont""")

	run("mv ./*.o build/mac/libbirdfont/ ")

	run("gcc -dynamiclib -Wl,-headerpad_max_install_names,-undefined,dynamic_lookup,-compatibility_version,1.0,-current_version,1.0,-install_name,/usr/local/lib/libbirdfont.dylib -shared build/mac/libbirdfont/*.o $(pkg-config --cflags --libs libxml-2.0) $(pkg-config --cflags --libs gio-2.0) $(pkg-config --cflags --libs cairo) $(pkg-config --cflags --libs glib-2.0) $(pkg-config --cflags --libs gdk-pixbuf-2.0) $(pkg-config --cflags --libs webkit-1.0) -shared -o libbirdfont.dylib")

	run("mv libbirdfont.dylib build/mac/bin/")

	# birdfont
	run("mkdir -p build/mac/birdfont")
	
	run("valac -C birdfont/* --vapidir=./ --pkg libxml-2.0 --pkg gio-2.0  --pkg cairo --pkg libsoup-2.4 --pkg gdk-pixbuf-2.0 --pkg webkit-1.0 --pkg gtk+-2.0 --pkg libbirdfont")

	run("mv birdfont/*.c build/mac/birdfont/")

	run("""gcc -c ./build/mac/libbirdfont/birdfont.h build/mac/birdfont/*.c -D 'GETTEXT_PACKAGE="birdfont"' $(pkg-config --cflags --libs libxml-2.0) $(pkg-config --cflags --libs gio-2.0) $(pkg-config --cflags --libs cairo) $(pkg-config --cflags --libs glib-2.0) $(pkg-config --cflags --libs gdk-pixbuf-2.0) $(pkg-config --cflags --libs webkit-1.0) -I ./build/mac/libbirdfont/""")

	run("mv ./*.o build/mac/birdfont/")

	run("gcc build/mac/birdfont/*.o ./build/mac/bin/libbirdfont.dylib $(pkg-config --cflags --libs libxml-2.0) $(pkg-config --cflags --libs gio-2.0) $(pkg-config --cflags --libs cairo) $(pkg-config --cflags --libs glib-2.0) $(pkg-config --cflags --libs gdk-pixbuf-2.0) $(pkg-config --cflags --libs webkit-1.0) $(pkg-config --cflags --libs gtk+-2.0) -o ./build/mac/bin/birdfont")

	# birdfont-export
	run("mkdir -p build/mac/birdfont-export")
	
	run("valac -C birdfont-export/* --vapidir=./ --pkg libxml-2.0 --pkg gio-2.0  --pkg cairo --pkg libsoup-2.4 --pkg gdk-pixbuf-2.0 --pkg webkit-1.0 --pkg gtk+-2.0 --pkg libbirdfont")

	run("mv birdfont-export/*.c build/mac/birdfont-export/")

	run("""gcc -c ./build/mac/libbirdfont/birdfont.h build/mac/birdfont-export/*.c -D 'GETTEXT_PACKAGE="birdfont"' $(pkg-config --cflags --libs libxml-2.0) $(pkg-config --cflags --libs gio-2.0) $(pkg-config --cflags --libs cairo) $(pkg-config --cflags --libs glib-2.0) $(pkg-config --cflags --libs gdk-pixbuf-2.0) $(pkg-config --cflags --libs webkit-1.0) -I ./build/mac/libbirdfont/""")

	run("mv ./*.o build/mac/birdfont-export/")

	run("gcc build/mac/birdfont-export/*.o ./build/mac/bin/libbirdfont.dylib $(pkg-config --cflags --libs libxml-2.0) $(pkg-config --cflags --libs gio-2.0) $(pkg-config --cflags --libs cairo) $(pkg-config --cflags --libs glib-2.0) $(pkg-config --cflags --libs gdk-pixbuf-2.0) $(pkg-config --cflags --libs webkit-1.0) $(pkg-config --cflags --libs gtk+-2.0) -o ./build/mac/bin/birdfont-export")

	# copy files 
	run("mkdir -p build/mac/birdfont.app")
	run("mkdir -p build/mac/birdfont.app/Contents")
	run("mkdir -p build/mac/birdfont.app/Contents/MacOs")
	run("mkdir -p build/mac/birdfont.app/Contents/Resources")

	run("cp build/mac/bin/* build/mac/birdfont.app/Contents/MacOs")
	run("cp mac/birdfont.sh build/mac/birdfont.app/Contents/MacOs")
	run("cp mac/Info.plist build/mac/birdfont.app/")
	run("cp -r layout build/mac/birdfont.app/Contents/MacOs")
	run("cp -r icons build/mac/birdfont.app/Contents/MacOs")
	run("cp mac/birdfont.icns build/mac/birdfont.app/Contents/Resources")
	
	for lib in LOCAL_LIBS:
		run("cp /opt/local/lib/" + lib + ".dylib mac/Info.plist build/mac/birdfont.app/Contents/MacOs")
			
	run("cp /usr/lib/libgcc_s.1.dylib ./build/mac/birdfont.app/Contents/MacOs")

	# library path for libbirdfont	
	for lib in LOCAL_LIBS:
		run("install_name_tool -change /opt/local/lib/" + lib + ".dylib @executable_path/" + lib 
			+ ".dylib build/mac/birdfont.app/Contents/MacOs/libbirdfont.dylib")
		
	run("install_name_tool -change /usr/lib/libgcc_s.1.dylib @executable_path/libgcc_s.1.dylib "
		+ "build/mac/birdfont.app/Contents/MacOs/libbirdfont.dylib")

	run("install_name_tool -change /usr/local/lib/libbirdfont.dylib @executable_path/libbirdfont.dylib "
		+ "build/mac/birdfont.app/Contents/MacOs/libbirdfont.dylib")	

	# library path for birdfont	
	for lib in LOCAL_LIBS:
		run("install_name_tool -change /opt/local/lib/" + lib + ".dylib @executable_path/" + lib 
			+ ".dylib build/mac/birdfont.app/Contents/MacOs/birdfont")
		
	run("install_name_tool -change /usr/lib/libgcc_s.1.dylib @executable_path/libgcc_s.1.dylib "
		+ "build/mac/birdfont.app/Contents/MacOs/birdfont")

	run("install_name_tool -change /usr/local/lib/libbirdfont.dylib @executable_path/libbirdfont.dylib "
		+ "build/mac/birdfont.app/Contents/MacOs/birdfont")	

	run("install_name_tool -change /usr/local/lib/libbirdfont.dylib @executable_path/libbirdfont.dylib "
		+ "build/mac/birdfont.app/Contents/MacOs/birdfont-export")		
#	run("rm -rf build/mac/birdfont.dmg")	
#	run("hdiutil create -megabytes 50 -fs HFS+ -volname birdfont build/mac/birdfont")
#	run("open build/mac/birdfont.dmg")	
#	run("cp -r build/mac/birdfont.app /Volumes/birdfont/")
#	run("hdiutil detach /Volumes/birdfont")	

	print ("Done.");

build()
