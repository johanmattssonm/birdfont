#! /usr/bin/env python
# encoding: UTF-8
# Thomas Nagy 2008-2010 (ita)

"""

Doxygen support

Variables passed to bld():
* doxyfile -- the Doxyfile to use

ported from waf 1.5 (incomplete)
"""

from fnmatch import fnmatchcase
import os, os.path, re, stat
from waflib import Task, Utils, Node, Logs
from waflib.TaskGen import feature

DOXY_STR = '${DOXYGEN} - '
DOXY_FMTS = 'html latex man rft xml'.split()
DOXY_FILE_PATTERNS = '*.' + ' *.'.join('''
c cc cxx cpp c++ java ii ixx ipp i++ inl h hh hxx hpp h++ idl odl cs php php3
inc m mm py f90c cc cxx cpp c++ java ii ixx ipp i++ inl h hh hxx
'''.split())

re_nl = re.compile('\\\\\r*\n', re.MULTILINE)

class doxygen(Task.Task):
	vars  = ['DOXYGEN', 'DOXYFLAGS']
	color = 'BLUE'

	def runnable_status(self):
		'''
		self.pars are populated in runnable_status - because this function is being
		run *before* both self.pars "consumers" - scan() and run()

		set output_dir (node) for the output
		'''

		for x in self.run_after:
			if not x.hasrun:
				return Task.ASK_LATER

		if not getattr(self, 'pars', None):
			txt = self.inputs[0].read()
			txt = re_nl.sub('', txt)
			self.pars = Utils.str_to_dict(txt)
			if not self.pars.get('OUTPUT_DIRECTORY'):
				self.pars['OUTPUT_DIRECTORY'] = self.inputs[0].parent.get_bld().abspath()
			if not self.pars.get('INPUT'):
				self.pars['INPUT'] = self.inputs[0].parent.abspath()

		if not getattr(self, 'output_dir', None):
			bld = self.generator.bld
			# First try to find an absolute path, then find or declare a relative path
			self.output_dir = bld.root.find_dir(self.pars['OUTPUT_DIRECTORY'])
			if not self.output_dir:
				self.output_dir = bld.path.find_or_declare(self.pars['OUTPUT_DIRECTORY'])


		self.signature()
		return Task.Task.runnable_status(self)

	def scan(self):
		if self.pars.get('RECURSIVE') == 'YES':
			Logs.warn("Doxygen RECURSIVE dependencies are not supported")

		inputs = self.pars.get('INPUT').split()
		exclude_patterns = self.pars.get('EXCLUDE_PATTERNS', '').split()
		file_patterns = self.pars.get('FILE_PATTERNS', '').split()
		if not file_patterns:
			file_patterns = DOXY_FILE_PATTERNS

		nodes = []
		names = []
		for i in inputs:
			node = self.generator.bld.root.make_node(i)
			if node:
				if os.path.isdir(node.abspath()):
					for m in node.ant_glob(file_patterns):
						nodes.append(self.generator.bld.root.make_node(m.abspath()))
				else:
					nodes.append(node)
			else:
				names.append(i)

		return (nodes, names)

	def run(self):
		code = '\n'.join(['%s = %s' % (x, self.pars[x]) for x in self.pars])
		code = code.encode() # for python 3
		#fmt = DOXY_STR % (self.inputs[0].parent.abspath())
		cmd = Utils.subst_vars(DOXY_STR, self.env)
		env = self.env.env or None
		proc = Utils.subprocess.Popen(cmd, shell=True, stdin=Utils.subprocess.PIPE, env=env, cwd=self.generator.bld.path.get_bld().abspath())
		proc.communicate(code)
		return proc.returncode

	def post_run(self):
		nodes = self.output_dir.ant_glob('**/*')
		for x in nodes:
			x.sig = Utils.h_file(x.abspath())
		self.outputs += nodes
		return Task.Task.post_run(self)

	#def install(self):
	#	if getattr(self.generator, 'install_to', None):
	#		update_build_dir(self.inputs[0].parent, self.env)
	#		pattern = getattr(self, 'instype', 'html/*')
	#		self.generator.bld.install_files(self.generator.install_to, self.generator.path.ant_glob(pattern, dir=0, src=0))

class tar(Task.Task):
	"quick tar creation"
	run_str = '${TAR} ${TAROPTS} ${TGT} ${SRC}'
	color   = 'RED'
	after   = ['doxygen']
	def runnable_status(self):
		for x in getattr(self, 'input_tasks', []):
			if not x.hasrun:
				return Task.ASK_LATER

		if not getattr(self, 'tar_done_adding', None):
			# execute this only once
			self.tar_done_adding = True
			for x in getattr(self, 'input_tasks', []):
				self.set_inputs(x.outputs)
			if not self.inputs:
				return Task.SKIP_ME
		return Task.Task.runnable_status(self)

	def __str__(self):
		tgt_str = ' '.join([a.nice_path(self.env) for a in self.outputs])
		return '%s: %s\n' % (self.__class__.__name__, tgt_str)

@feature('doxygen')
def process_doxy(self):
	if not getattr(self, 'doxyfile', None):
		self.generator.bld.fatal('no doxyfile??')

	node = self.doxyfile
	if not isinstance(node, Node.Node):
		node = self.path.find_resource(node)
	if not node:
		raise ValueError('doxygen file not found')

	# the task instance
	dsk = self.create_task('doxygen', node)

	if getattr(self, 'doxy_tar', None):
		tsk = self.create_task('tar')
		tsk.input_tasks = [dsk]
		tsk.set_outputs(self.path.find_or_declare(self.doxy_tar))
		if self.doxy_tar.endswith('bz2'):
			tsk.env['TAROPTS'] = ['cjf']
		elif self.doxy_tar.endswith('gz'):
			tsk.env['TAROPTS'] = ['czf']
		else:
			tsk.env['TAROPTS'] = ['cf']

def configure(conf):
	conf.find_program('doxygen', var='DOXYGEN')
	conf.find_program('tar', var='TAR')

