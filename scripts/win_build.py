#!/usr/bin/python
"""
Copyright (C) 2012 2013 Johan Mattsson

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

import configfile
import version
from run import run
from translations import compile_translations

VERSION = version.VERSION

WIN32_LIBS = [
	'glib-2.0',
	'libxml-2.0',
	'gio-2.0',
	'libsoup-2.4',
	'gtk+-2.0',
	'webkit-1.0'
]

WIN32_DLLS = [ 
	"libcairo-2.dll",
	"libgdk-win32-2.0-0.dll",
	"libgdk_pixbuf-2.0-0.dll",
	"libgio-2.0-0.dll",
	"libglib-2.0-0.dll",
	"libgobject-2.0-0.dll",
	"libgthread-2.0-0.dll",
	"libgtk-win32-2.0-0.dll",
	"libxml2-2.dll",
	"libfontconfig-1.dll",
	"libfreetype-6.dll",
	"libpixman-1-0.dll",
	"libpng15-15.dll",
	"zlib1.dll",
	"libpixman-1-0.dll",
	"libpng15-15.dll",
	"libintl-8.dll",
	"libgmodule-2.0-0.dll",
	"libffi-5.dll",
	"libgobject-2.0-0.dll",
	"libjasper-1.dll",
	"libjpeg-8.dll",
	"libtiff-5.dll",
	"libgdk_pixbuf-2.0-0.dll",
	"libpango-1.0-0.dll",
	"libpangocairo-1.0-0.dll",
	"libgdk-win32-2.0-0.dll",
	"libgmodule-2.0-0.dll",
	"libexpat-1.dll",
	"libpangoft2-1.0-0.dll",
	"libpangowin32-1.0-0.dll",
	"libpangocairo-1.0-0.dll",
	"libgdk-win32-2.0-0.dll",
	"libpangoft2-1.0-0.dll",
	"libpangowin32-1.0-0.dll",
	"libpangocairo-1.0-0.dll",
	"libatk-1.0-0.dll",
	"libsoup-2.4-1.dll",
	"libsqlite3-0.dll",
	"libxslt-1.dll",
	"libgcc_s_sjlj-1.dll",
	"libstdc++-6.dll",
	"libjavascriptcoregtk-1.0-0.dll",
	"libenchant-1.dll",
	"libgailutil-18.dll",
	"libwebkitgtk-1.0-0.dll",
	"pthreadGC2.dll"
]
		
def configure():
	print("")
	print("Crosscompile for windows")
	
	run('./configure')
		
	run('i686-w64-mingw32-gcc --version')
	run('i686-w64-mingw32-pkg-config --version')	
	run('windres --version')	
	run('wine --version')
	run('ls ' + os.getenv("HOME") + "/.wine/drive_c/Program/NSIS/makensis.exe")
	
	for pkg in WIN32_LIBS:
		 run('i686-w64-mingw32-pkg-config --cflags --libs '+ pkg)

def build():
	run("mkdir -p ./build/supplement")
	run("mkdir -p ./build/win32")
	run("mkdir -p ./build/win32/libbirdfont")
	run("mkdir -p ./build/win32/birdfont")
	run("mkdir -p ./build/win32/birdfont-export")

	run("windres ./resources/win32/icon.rc -O coff -o ./build/icon.res")

	# generate c code
	run("cp ./libbirdfont/OpenFontFormat/*.c ./build/win32/libbirdfont/")
	run("""valac -C \
		./libbirdfont/*.vala \
		./libbirdfont/OpenFontFormat/*.vala \
		--basedir ./build/win32/libbirdfont/ \
		--library libbirdfont \
		-H ./build/win32/libbirdfont/birdfont.h \
		--pkg libxml-2.0 \
		--pkg gio-2.0 \
		--pkg cairo \
		--pkg libsoup-2.4 \
		--pkg gdk-pixbuf-2.0 \
		--pkg webkit-1.0""")

	run("""valac -C --basedir ./build/win32/birdfont \
		./birdfont/* \
		--vapidir=./ \
		--pkg libxml-2.0 \
		--pkg gio-2.0 \
		--pkg cairo \
		--pkg libsoup-2.4 \
		--pkg gdk-pixbuf-2.0 \
		--pkg webkit-1.0 \
		--pkg gtk+-2.0 \
		--pkg libbirdfont""")
	
	run("""valac -C --basedir ./build/win32/birdfont-export/ \
		./birdfont-export/* \
		--vapidir=./ \
		--pkg libxml-2.0 \
		--pkg gio-2.0 \
		--pkg cairo \
		--pkg libsoup-2.4 \
		--pkg gdk-pixbuf-2.0 \
		--pkg webkit-1.0 \
		--pkg gtk+-2.0 \
		--pkg libbirdfont""")

	# compile c code
	run("""i686-w64-mingw32-gcc \
			-c ./build/win32/libbirdfont/birdfont.h \
			./build/win32/birdfont/Main.c \
			./build/win32/birdfont/GtkWindow.c \
			./build/win32/birdfont-export/BirdfontExport.c \
			./build/win32/libbirdfont/*.c ./ \
			-D 'GETTEXT_PACKAGE="birdfont"' \
			-I ./build/win32/libbirdfont/ \
			-mthreads \
			$(i686-w64-mingw32-pkg-config --cflags --libs glib-2.0) \
			$(i686-w64-mingw32-pkg-config --cflags --libs libxml-2.0) \
			$(i686-w64-mingw32-pkg-config --cflags --libs gio-2.0) \
			$(i686-w64-mingw32-pkg-config --cflags --libs libsoup-2.4) \
			$(i686-w64-mingw32-pkg-config --cflags --libs gtk+-2.0) \
			$(i686-w64-mingw32-pkg-config --cflags --libs webkit-1.0)""");
	
	# move object files to their folders
	run("""mv BirdfontExport.o ./build/win32/birdfont-export """)
	run("""mv Main.o ./build/win32/birdfont """)
	run("""mv GtkWindow.o ./build/win32/birdfont """)
	run("""mv *.o ./build/win32/libbirdfont/ """)

	# link binaries
	run("""i686-w64-mingw32-gcc \
		-shared \
		./build/win32/libbirdfont/*.o \
		./build/icon.res \
		-Wl,-subsystem,windows \
		-mthreads \
		-L/usr/i686-w64-mingw32/sys-root/mingw/lib \
		-static -B static -lintl.dll -B static -l glib-2.0.dll -B static -l xml2.dll  \
		-B static -lgio-2.0.dll -B static -l soup-2.4.dll \
		-B static -l webkitgtk-1.0.dll  -B static -lgtk-win32-2.0.dll -B static -lgdk-win32-2.0.dll -B static -latk-1.0.dll -B static -lgio-2.0.dll -B static -lpangowin32-1.0.dll -B static -lpangocairo-1.0.dll -B static -lgdk_pixbuf-2.0.dll -B static -lpango-1.0.dll -B static -lcairo.dll -B static -lgobject-2.0.dll -B static -lgmodule-2.0.dll -B static -lgthread-2.0.dll -B static -lglib-2.0.dll \
		-l freetype.dll\
		-static -o libbirdfont.dll""")
	
	run("""i686-w64-mingw32-ar rcs ./build/libbirdfont.dll.a ./build/win32/libbirdfont/*.o""")

	run("""i686-w64-mingw32-gcc \
		./build/win32/birdfont/Main.o \
		./build/win32/birdfont/GtkWindow.o \
		./build/icon.res \
		-Wl,-subsystem,windows \
		-mthreads \
		-L./build/ \
		-L/usr/i686-w64-mingw32/sys-root/mingw/lib \
		-static -B -static -l birdfont.dll \
		-static -B static -lintl.dll -B static -l glib-2.0.dll -B static -l xml2.dll  \
		-B static -l gio-2.0.dll -B static -l soup-2.4.dll \
		-B static -l webkitgtk-1.0.dll  -B static -l gtk-win32-2.0.dll -B static -l gdk-win32-2.0.dll -B static -l atk-1.0.dll -B static -l gio-2.0.dll -B static -l pangowin32-1.0.dll -B static -l pangocairo-1.0.dll -B static -l gdk_pixbuf-2.0.dll -B static -l pango-1.0.dll -B static -l cairo.dll -B static -l gobject-2.0.dll -B static -l gmodule-2.0.dll -B static -l gthread-2.0.dll -B static -l glib-2.0.dll \
		-l freetype.dll \
		-static -o birdfont.exe""")

	run("""i686-w64-mingw32-gcc \
		./build/win32/birdfont/Main.o \
		./build/win32/birdfont/GtkWindow.o \
		./build/icon.res \
		-mthreads \
		-L./build/ \
		-L/usr/i686-w64-mingw32/sys-root/mingw/lib \
		-static -B -static -l birdfont.dll \
		-static -B static -lintl.dll -B static -l glib-2.0.dll -B static -l xml2.dll  \
		-B static -l gio-2.0.dll -B static -l soup-2.4.dll \
		-B static -l webkitgtk-1.0.dll  -B static -l gtk-win32-2.0.dll -B static -l gdk-win32-2.0.dll -B static -l atk-1.0.dll -B static -l gio-2.0.dll -B static -l pangowin32-1.0.dll -B static -l pangocairo-1.0.dll -B static -l gdk_pixbuf-2.0.dll -B static -l pango-1.0.dll -B static -l cairo.dll -B static -l gobject-2.0.dll -B static -l gmodule-2.0.dll -B static -l gthread-2.0.dll -B static -l glib-2.0.dll \
		-l freetype.dll \
		-static -o birdfont_terminal.exe""")

	run("""i686-w64-mingw32-gcc \
		./build/win32/birdfont-export/BirdfontExport.o \
		./build/icon.res \
		-Wl,-subsystem,windows \
		-mthreads \
		-L./build/ \
		-L/usr/local/lib -lfreetype -lz \
		-L/usr/i686-w64-mingw32/sys-root/mingw/lib \
		-static -B -static -l birdfont.dll \
		-static -B static -lintl.dll -B static -l glib-2.0.dll -B static -l xml2.dll  \
		-B static -l gio-2.0.dll -B static -l soup-2.4.dll \
		-B static -l webkitgtk-1.0.dll  -B static -l gtk-win32-2.0.dll -B static -l gdk-win32-2.0.dll -B static -l atk-1.0.dll -B static -l gio-2.0.dll -B static -l pangowin32-1.0.dll -B static -l pangocairo-1.0.dll -B static -l gdk_pixbuf-2.0.dll -B static -l pango-1.0.dll -B static -l cairo.dll -B static -l gobject-2.0.dll -B static -l gmodule-2.0.dll -B static -l gthread-2.0.dll -B static -l glib-2.0.dll \
		-l freetype.dll \
		-static -o birdfont-export.exe""")

	run("mv birdfont-export.exe ./build/supplement/")
	run("mv birdfont.exe ./build/supplement/")
	run("mv birdfont_terminal.exe ./build/supplement/")
	run("mv libbirdfont.dll ./build/supplement/")

	compile_translations ()

	copy_runtime_dependencies ()
	generate_nsi()
	
	os.chdir('../../')
	run(os.getenv("HOME") + "/.wine/drive_c/Program/NSIS/makensis.exe ./build/supplement/birdfont_installer.nsi")
	
def generate_nsi():
	print ('generating build/supplement/birdfont_installer.nsi')

	run('mkdir -p ./build/supplement')

	f = open('./build/supplement/birdfont_installer.nsi', 'w+')
	f.write("""; windows installation script generated by by build script

Name "Birdfont"
""")

	f.write("OutFile \"..\\")
	f.write("birdfont-")
	f.write(VERSION)
	f.write(".exe\"")
	
	f.write("""
InstallDir $PROGRAMFILES\Birdfont
InstallDirRegKey HKLM "Software\NSIS_Birdfont" "Install_Dir"

Icon "birdfont.ico"

; Request application privileges for Windows Vista
RequestExecutionLevel admin

;--------------------------------

Page components
Page directory
Page instfiles

UninstPage uninstConfirm
UninstPage instfiles

;--------------------------------

Section "Birdfont (required)"

  SectionIn RO
""");

	os.chdir('./build/supplement')
	write_files ('.', f)

	f.write("""

  SetOutPath $INSTDIR

  ; Write the installation path into the registry
  WriteRegStr HKLM SOFTWARE\NSIS_Birdfont "Install_Dir" "$INSTDIR"
  
  ; Write the uninstall keys for Windows
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Birdfont" "DisplayName" "NSIS Birdfont"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Birdfont" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Birdfont" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Birdfont" "NoRepair" 1
  WriteUninstaller "uninstall.exe"
  
SectionEnd

Section "Start Menu Shortcuts"

  CreateDirectory "$SMPROGRAMS\Birdfont"
  CreateShortCut "$SMPROGRAMS\Birdfont\Uninstall.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0
  CreateShortCut "$SMPROGRAMS\Birdfont\Birdfont.lnk" "$INSTDIR\\birdfont.exe" ""
  
  CreateShortCut "$DESKTOP\Birdfont.lnk" "$INSTDIR\\birdfont.exe" ""
  
SectionEnd

;--------------------------------

; Uninstaller

Section "Uninstall"
  
  ; Remove registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Birdfont"
  DeleteRegKey HKLM SOFTWARE\NSIS_Birdfont

""")

	remove_files ('.', f)

	f.write("""

  Delete $INSTDIR\uninstall.exe
  RMDir "$INSTDIR\Birdfont"
   
  Delete "$SMPROGRAMS\Birdfont\*.*"
  RMDir "$SMPROGRAMS\Birdfont"

  Delete "$DESKTOP\Birdfont.lnk"

SectionEnd
""")

def write_files (dir, f):
	filenames = os.walk(dir)

	f.write("  SetOutPath $INSTDIR\n")
	
	for path in (os.path.join(dir, f) for f in os.listdir(dir)):
		if not os.path.isdir(path):
			f.write("  File \"")
			f.write(path.replace ('./', '').replace ('/', '\\'))
			f.write("\"\n")
				
	for dirname, dirnames, filenames in os.walk(dir):
		for subdirname in dirnames:
			ndir = os.path.join(dirname, subdirname)
			wdir = ndir.replace ('./', '').replace ('/', '\\')
			
			f.write("\n")
			f.write("  SetOutPath $INSTDIR\\")
			f.write(wdir)
			f.write("\n")
			
			dirList = os.listdir(ndir)
			for fname in dirList:
				fp = os.path.join(ndir, fname) 
				if not os.path.isdir(fp):
					f.write("  File ")
					f.write(wdir)
					f.write("\\")
					f.write(fname)
					f.write("\n")

def remove_files (dir, f):
	for path in (os.path.join(dir, f) for f in os.listdir(dir)):
		if os.path.isdir(path):
			remove_files (path, f)
		else:
			f.write("  Delete \"$INSTDIR\\")
			f.write(path.replace ('./', '').replace ('/', '\\'))
			f.write("\"\n")
	
	if dir == '.':
		f.write("  RMDir \"$INSTDIR\"\n")	
	else:
		f.write("  RMDir \"$INSTDIR\\")
		f.write(dir.replace ('./', '').replace ('/', '\\'))
		f.write("\"\n")
		
def copy_runtime_dependencies ():

	MINGW = "/usr/i686-w64-mingw32/sys-root/mingw"
	MINGW_BIN = MINGW + "/bin"

	run("cp /usr/share/unicode/NamesList.txt ./build/supplement/")

	run("cp ./README ./build/supplement/")
	run("cp ./NEWS ./build/supplement/")
	
	run("cp -ra ./layout/ ./build/supplement/")
	run("cp -ra ./icons/ ./build/supplement/")
	run("cp -ra ./build/locale ./build/supplement/")
	
	run("cp ./resources/win32/birdfont.ico ./build/supplement/")
	run("cp -r " + MINGW + "/etc ./build/supplement/")

	run("cp " + MINGW_BIN + "/gspawn-win32-helper.exe ./build/supplement/")
	run("cp " + MINGW_BIN + "/gspawn-win32-helper-console.exe ./build/supplement/")

	# DLL-hell
	for dll in WIN32_DLLS:
		run("cp " + MINGW_BIN + "/" + dll + " ./build/supplement/")

configfile.write_config ("")
build ()	
