#!/usr/bin/python3

import dodo
from sys import platform

from scripts.builder import process_tasks
from scripts import config
from scripts.translations import compile_translations

if not platform == "msys":
	process_tasks(dodo.task_libbirdgems())
	process_tasks(dodo.task_libbirdfont())
else:
	process_tasks(dodo.make_libbirdgems('libbirdgems.dll', []))
	process_tasks(dodo.make_libbirdfont('libbirdfont.dll', ['libbirdgems.dll']))

if config.GTK:
	process_tasks(dodo.task_birdfont())
	process_tasks(dodo.task_birdfont_autotrace())
	process_tasks(dodo.task_birdfont_export())
	process_tasks(dodo.task_birdfont_import())
	process_tasks(dodo.task_man())

compile_translations()

print('Done')
