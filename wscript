VERSION = '0.1'
APPNAME = 'Supplement'

top = '.'
out = 'build'

def options(opt):
	opt.load('compiler_c')
	opt.load('vala')
	
def configure(conf):
	conf.load('compiler_c vala')

	conf.check_cfg(package='glib-2.0', uselib_store='GLIB',atleast_version='2.16.0', mandatory=1, args='--cflags --libs')
	conf.check_cfg(package='gio-2.0',  uselib_store='GIO', atleast_version='2.16.0', mandatory=1, args='--cflags --libs')
	conf.check_cfg(package='gtk+-2.0', uselib_store='GTK', atleast_version='2.16.0', mandatory=1, args='--cflags --libs')
	conf.check_cfg(package='libxml-2.0', uselib_store='XML', mandatory=1, args='--cflags --libs')
	conf.check_cfg(package='webkit-1.0', uselib_store='WEB', mandatory=1, args='--cflags --libs')
	
	conf.env.append_unique('VALAFLAGS', ['--thread', '--pkg', 'webkit-1.0', '--enable-experimental', '--enable-experimental-non-null', '--vapidir=../../'])
	
def build(bld):
	bld.recurse('src')
