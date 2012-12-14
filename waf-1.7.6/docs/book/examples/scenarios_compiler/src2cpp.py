from waflib.Task import Task
class src2cpp(Task):
	run_str = '${SRC[0].abspath()} ${SRC[1].abspath()} ${TGT}'
	color   = 'PINK'

from waflib.TaskGen import extension

@extension('.src')
def process_src(self, node):
	tg = self.bld.get_tgen_by_name('comp')
	comp = tg.link_task.outputs[0]
	tsk = self.create_task('src2cpp', [comp, node], node.change_ext('.cpp'))
	self.source.extend(tsk.outputs)

