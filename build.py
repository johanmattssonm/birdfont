#!/usr/bin/python3

import dodo
from scripts.builder import process_tasks
			
process_tasks(dodo.task_libbirdgems())
process_tasks(dodo.task_libbirdfont())
process_tasks(dodo.task_birdfont())
process_tasks(dodo.task_birdfont_autotrace())
process_tasks(dodo.task_birdfont_export())
process_tasks(dodo.task_birdfont_import())

print('Done')
