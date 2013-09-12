#!/usr/bin/python 
import os
import subprocess
import glob
import platform
from optparse import OptionParser
from scripts import config
from scripts import version
from scripts.run import run

def install (file, dir):
	f = dest + prefix + dir + '/'
	s = file.rfind ('/')
	if s > -1:
		f += file[s + 1:]
	else:
		f += file
	print ("install: " + f)
	run ('install -d ' + dest + prefix + dir)
	run ('install ' + file + ' ' + dest + prefix + dir + '/')
	installed.write (f + "\n")

if not os.path.exists ("build/configured"):
	print ("Project is not configured")
	exit (1)

if not os.path.exists ("build/installed"):
        print ("Project is not built")
        exit (1)

parser = OptionParser()
parser.add_option ("-d", "--dest", dest="dest", help="install to this directory", metavar="DEST")
parser.add_option ("-m", "--bsd-manpages", dest="nogzip", help="don't gzip manpages")

(options, args) = parser.parse_args()

if not options.dest:
	options.dest = ""

if not options.nogzip:
    bsd_manpages = True
else:
    bsd_manpages = False
	
prefix = config.PREFIX
dest = options.dest

# create uninstall file
installed = open ('build/installed', 'w')
installed.write ('build/installed\n')

# install it:
for file in os.listdir('./layout'):
	install ('layout/' + file, '/share/birdfont/layout')

for file in os.listdir('./icons'):
	install ('icons/' + file, '/share/birdfont/icons')

install ('resources/linux/birdfont.desktop', '/share/applications')
install ('resources/linux/birdfont.png', '/share/icons/hicolor/48x48/apps')

if os.path.isfile ('build/bin/birdfont'):
	install ('build/bin/birdfont', '/bin')

install ('build/bin/birdfont-export', '/bin')

libdir = '/lib'
#library
if platform.machine() == 'i386' or platform.machine() == 's390' or platform.machine() == 'ppc' or platform.machine() == 'armv7hl':
   libdir = '/lib'
if platform.machine() == 'x86_64' or platform.machine() == 's390x' or platform.machine() == 'ppc64':
   libdir = '/lib64'

if os.path.isfile ('build/bin/libbirdfont.so.' + version.SO_VERSION):
	install ('build/bin/libbirdfont.so.' + version.SO_VERSION, libdir)
	install ('build/bin/libbirdfont.so', libdir)
elif os.path.isfile ('build/libbirdfont.so.' + version.SO_VERSION):
	install ('build/libbirdfont.so.' + version.SO_VERSION, libdir)
	install ('build/libbirdfont.so', libdir)
elif os.path.isfile ('build/bin/libbirdfont.' + version.SO_VERSION + '.dylib'):
	install ('build/bin/libbirdfont.' + version.SO_VERSION + '.dylib', libdir)
	install ('build/bin/libbirdfont.dylib', libdir)
else:
	print ("Can not find libbirdfont.")
	exit (1)
	
#manpages
if not bsd_manpages:
    install ('build/birdfont.1.gz', '/share/man/man1')
    install ('build/birdfont-export.1.gz', '/share/man/man1')
else:
    install ('resources/linux/birdfont.1', '/man/man1')
    install ('resources/linux/birdfont-export.1', '/man/man1')

# translations
for lang_dir in glob.glob('build/locale/*'):
	lc = lang_dir.replace ('build/locale/', "")
	install ('build/locale/' + lc + '/LC_MESSAGES/birdfont.mo', '/share/locale/' + lc + '/LC_MESSAGES' );

installed.close ()
