import subprocess
import os
import time;

DOIT_CONFIG = {
	'default_tasks': [
		'build',
		'birdfont',
		'birdfont_export',
		'libbirdfont_c', 
		'libbirdfont_o', 
		'libbirdfont_so', 
		'compile_translations',
		'man'
	]
}

def task_build ():
	if not os.path.exists ("build/configured"):
		print ("Project is not configured")
		exit (1)
		
	return  {
		'actions': ['echo "Build"'],
	}	
		
def task_libbirdfont_c ():
	action = "valac -C "
	action += "--basedir ./build/libbirdfont "
	action += "--enable-experimental-non-null "
	action += "--vapidir=./ --thread --save-temps "
	action += """-X '-D GETTEXT_PACKAGE="birdfont"' """
	action += "--library birdfont "
	action += "-H ./build/birdfont.h "
	action += "--vapi ./build/birdfont.vapi "
	action += "-o ../build/libbirdfont.so "
	action += "-X -fPIC "
	action += "-X -shared "
	action += "--pkg gtk+-2.0 " 
	action += "--pkg libxml-2.0 "
	action += "--pkg webkit-1.0 "
	
	actions = [ action + "libbirdfont/*.vala" ]
	
	libbirdfont_sources = os.listdir('libbirdfont/')	
	files = []
	for f in libbirdfont_sources:
		files += ["libbirdfont/" + f]
		
	return {
		'actions': actions,
		'file_dep': files,
		'targets': [ 'build/birdfont.h', 'build/birdfont.vapi'],
	}

def task_libbirdfont_o ():
	action = "gcc "
	param = """ -D 'GETTEXT_PACKAGE="birdfont"' \
			$(pkg-config --cflags --libs glib-2.0) \
			$(pkg-config --cflags --libs libxml-2.0) \
			$(pkg-config --cflags --libs gio-2.0) \
			$(pkg-config --cflags --libs libsoup-2.4) \
			$(pkg-config --cflags --libs cairo) \
			$(pkg-config --cflags --libs gdk-pixbuf-2.0) \
			$(pkg-config --cflags --libs webkit-1.0)"""

	libbirdfont_sources = os.listdir('libbirdfont/')	

	for src in libbirdfont_sources:
		yield { 
			'name': src.replace ('.vala', '.o'),
			'file_dep': [ 'build/libbirdfont/' + src.replace ('.vala', '.c') ],
			'actions': [action + param + "-c build/libbirdfont/" + src.replace ('.vala', '.c') + " -o build/libbirdfont/" + src.replace ('.vala', '.o')],
			'targets': [ 'build/libbirdfont/' + src.replace ('.vala', '.o') ],
			'task_dep': ['libbirdfont_c']
		}
	
def task_libbirdfont_so ():
	action = """gcc -shared build/libbirdfont/*.o \
			$(pkg-config --cflags --libs glib-2.0) \
			$(pkg-config --cflags --libs libxml-2.0) \
			$(pkg-config --cflags --libs gio-2.0) \
			$(pkg-config --cflags --libs libsoup-2.4) \
			$(pkg-config --cflags --libs cairo) \
			$(pkg-config --cflags --libs gdk-pixbuf-2.0) \
			$(pkg-config --cflags --libs webkit-1.0) \
			-o build/libbirdfont.so"""
		
	return {
		'actions': [ action ],
		'file_dep': [ 'build/libbirdfont/Config.c' ],
		'targets': [ 'build/libbirdfont.so' ],
		'task_dep': ['libbirdfont_o'], 
	}

def task_birdfont ():
	birdfont_sources = os.listdir('birdfont/')

	files = []
	for f in birdfont_sources:
		files += ["birdfont/" + f]
	
	action = """valac \
		--basedir ./build/main \
		-C ./build/birdfont.vapi \
		./birdfont/*.vala \
		-X ../build/libbirdfont/libbirdfont.so -X ./build/birdfont.h \
		--pkg gtk+-2.0 --pkg libxml-2.0 --pkg gdk-2.0 --pkg webkit-1.0"""
		
	yield {
		'name': 'compile_birdfont_executable',
		'actions': [ action ],
		'file_dep': files,
		'targets': [ 'build/main/Main.c' ],
		'task_dep': ['libbirdfont_o'], 
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
		'file_dep': [ 'build/main/Main.c' ],
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
	for file in os.listdir('./po'):
		if file == "birdfont.pot": continue
		
		loc = file.replace (".po", "")

		yield { 
			'name': loc + "_dir",
			'actions': ["mkdir -p build/locale/" + loc + "/LC_MESSAGES/"],
			'targets': [ "build/locale/" + loc + "/LC_MESSAGES/" ]
		}

		yield { 
			'name': loc + "_msgfmt",
			'actions': ["msgfmt --output=build/locale/" + loc + "/LC_MESSAGES/birdfont.mo ./po/" + loc + ".po"],
			'targets': [ "build/locale/" + loc + "/LC_MESSAGES/birdfont.mo" ]
		}

def task_man ():
		yield { 
			'name': "birdfont.1",
			'actions': ["gzip -9 -c ./linux/birdfont.1  > build/birdfont.1.gz"],
		}

		yield { 
			'name': "birdfont-export.1",
			'actions': ["gzip -9 -c ./linux/birdfont-export.1  > build/birdfont-export.1.gz"],
		}

def make_task(func):
    func.create_doit_tasks = func
    return func

@make_task
def task_distclean ():
	return  {
		'actions': ['rm -rf build dodo.pyc libbirdfont/Config.vala'],
	}	

def is_configured ():
	if not os.path.exists ("build/configured"):
		print ("Project is not configured")
		exit (1)
	
