#! /usr/bin/env python

"""
Strip a program/library after it is created. Use this tool as an example.

Usage::

	bld.program(features='strip', source='main.c', target='foo')

By using::

	@TaskGen.feature('cprogram', 'cxxprogram', 'fcprogram')

It is possible to have all the C, C++ and Fortran programs stripped automatically
"""

def configure(conf):
	conf.find_program('strip')

from waflib import Task, TaskGen
class strip(Task.Task):
	run_str = '${STRIP} ${SRC}'
	color   = 'BLUE'

@TaskGen.feature('strip')
@TaskGen.after('apply_link')
def add_strip_task(self):
	try:
		link_task = self.link_task
	except:
		return
	tsk = self.create_task('strip', self.link_task.outputs[0])
