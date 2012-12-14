#!/usr/bin/env python
# encoding: utf-8
# Thomas Nagy, 2010

"cuda"

import os
from waflib import Task
from waflib.TaskGen import extension
from waflib.Tools import ccroot, c_preproc
from waflib.Configure import conf

class cuda(Task.Task):
	run_str = '${NVCC} ${CUDAFLAGS} ${CXXFLAGS} ${FRAMEWORKPATH_ST:FRAMEWORKPATH} ${CPPPATH_ST:INCPATHS} ${DEFINES_ST:DEFINES} ${CXX_SRC_F}${SRC} ${CXX_TGT_F}${TGT}'
	color   = 'GREEN'
	ext_in  = ['.h']
	vars    = ['CCDEPS']
	scan    = c_preproc.scan
	shell   = False

@extension('.cu', '.cuda')
def c_hook(self, node):
	return self.create_compiled_task('cuda', node)

def configure(conf):
	conf.find_program('nvcc', var='NVCC')
	conf.find_cuda_libs()

@conf
def find_cuda_libs(self):
	"""
	find the cuda include and library folders

	use ctx.program(source='main.c', target='app', use='CUDA CUDART')
	"""

	if not self.env.NVCC:
		self.fatal('check for nvcc first')

	d = self.root.find_node(self.env.NVCC).parent.parent

	node = d.find_node('include')
	_includes = node and node.abspath() or ''

	_libpath = []
	for x in ('lib64', 'lib'):
		try:
			_libpath.append(d.find_node(x).abspath())
		except:
			pass

	# this should not raise any error
	self.check_cxx(header='cuda.h', lib='cuda', libpath=_libpath, includes=_includes)
	self.check_cxx(header='cuda.h', lib='cudart', libpath=_libpath, includes=_includes)

