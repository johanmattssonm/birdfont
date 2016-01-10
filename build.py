#!/usr/bin/python3

import dodo
from sys import platform

from scripts.builder import process_tasks
from scripts import config
from scripts.translations import compile_translations
from scripts import version

if platform == 'msys':
	process_tasks(dodo.make_libbirdgems('libbirdgems.dll', []))
	process_tasks(dodo.make_libbirdgems('libsvgbird.dll', []))
	process_tasks(dodo.make_libbirdfont('libbirdfont.dll', ['libbirdgems.dll', 'libsvgbird.dll']))
	process_tasks(dodo.make_libbirdfont('libbirdfont.dll', ['libbirdgems.dll', 'libsvgbird.dll']))
	process_tasks(dodo.make_birdfont_test('birdfont-test.exe', 
		['libbirdgems.dll', 'libbirdfont.dll', 'libsvgbird.dll']))
elif platform == 'darwin':
	gems = "libbirdgems." + str(version.LIBBIRDGEMS_SO_VERSION) + '.dylib'
	bird = "libbirdfont." + str(version.SO_VERSION) + '.dylib';
	svg = "libsvgbird." + str(version.LIBSVGBIRD_SO_VERSION) + '.dylib';
	process_tasks(dodo.make_libsvgbird(svg, []))
	process_tasks(dodo.make_libbirdgems(gems, []))
	process_tasks(dodo.make_libbirdfont(bird, [gems]))
	process_tasks(dodo.task_man())
else:
	process_tasks(dodo.task_libsvgbird())
	process_tasks(dodo.task_libbirdgems())
	process_tasks(dodo.task_libbirdfont())
	process_tasks(dodo.make_birdfont_test('birdfont-test', 
		['libsvgbird.so', 'libbirdgems.so', 'libbirdfont.so']))

if config.GTK:
	process_tasks(dodo.task_birdfont())
	process_tasks(dodo.task_birdfont_autotrace())
	process_tasks(dodo.task_birdfont_export())
	process_tasks(dodo.task_birdfont_import())
	process_tasks(dodo.task_man())

compile_translations()

print('Done')
