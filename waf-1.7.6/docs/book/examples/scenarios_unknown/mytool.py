#! /usr/bin/env python
# encoding: utf-8
# Thomas Nagy, 2008-2010 (ita)

import os
from waflib import Task, Utils, Context
from waflib.Utils import subprocess
from waflib.TaskGen import extension

@extension('.src')
def process_shpip(self, node):
	self.create_task('src2c', node)

class src2c(Task.Task):
	color = 'PINK'
	quiet = 1
	ext_out = ['.h']

	def run(self):
		cmd = '%s %s' % (self.env.COMP, self.inputs[0].abspath())
		cwd = self.inputs[0].parent.get_bld().abspath()
		out = self.generator.bld.cmd_and_log(cmd, cwd=cwd, quiet=Context.STDOUT)

		out = Utils.to_list(out)
		self.outputs = [self.generator.path.find_or_declare(x) for x in out]
		self.generator.bld.raw_deps[self.uid()] = [self.signature()] + self.outputs
		self.add_c_tasks(self.outputs)

	def add_c_tasks(self, lst):
		self.more_tasks = []
		for node in lst:
			if node.name.endswith('.h'):
				continue
			tsk = self.generator.create_compiled_task('c', node)
			self.more_tasks.append(tsk)

			tsk.env.append_value('INCPATHS', [node.parent.abspath()])

			if getattr(self.generator, 'link_task', None):
				self.generator.link_task.set_run_after(tsk)
				self.generator.link_task.inputs.append(tsk.outputs[0])

	def runnable_status(self):

		ret = super(src2c, self).runnable_status()
		if ret == Task.SKIP_ME:

			lst = self.generator.bld.raw_deps[self.uid()]
			if lst[0] != self.signature():
				return Task.RUN_ME

			nodes = lst[1:]
			for x in nodes:
				try:
					os.stat(x.abspath())
				except:
					return Task.RUN_ME

			nodes = lst[1:]
			self.set_outputs(nodes)
			self.add_c_tasks(nodes)

		return ret

