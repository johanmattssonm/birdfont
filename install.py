#!/usr/bin/python 
import os
import subprocess
import glob
import platform
from optparse import OptionParser
from scripts import config
from scripts import version
from scripts.run import run

def install (file, dir, mode):
	f = dest + prefix + dir + '/'
	s = file.rfind ('/')
	if s > -1:
		f += file[s + 1:]
	else:
		f += file
	print ("install: " + f)
	run ('install -d ' + dest + prefix + dir)
	run ('install -m ' + `mode` + ' '   + file + ' ' + dest + prefix + dir + '/')
	installed.write (f + "\n")

if not os.path.exists ("build/configured"):
	print ("Project is not configured")
	exit (1)

if not os.path.exists ("build/installed"):
        print ("Project is not built")
        exit (1)

parser = OptionParser()
parser.add_option ("-d", "--dest", dest="dest", help="install to this directory", metavar="DEST")
parser.add_option ("-m", "--unzip-manpages", dest="nogzip", help="don't gzip manpages", action="store_false")
parser.add_option ("-n", "--manpages-directory", dest="mandir", help="put man pages in this directory under prefix")

(options, args) = parser.parse_args()

if not options.dest:
	options.dest = ""

if not options.nogzip:
	zip_manpages = False
else:
	zip_manpages = true

if not options.mandir:
	mandir = "/man/man1"
else: 
	mandir = options.mandir

prefix = config.PREFIX
dest = options.dest

# create uninstall file
installed = open ('build/installed', 'w')
installed.write ('build/installed\n')

# install it:
for file in os.listdir('./layout'):
	install ('layout/' + file, '/share/birdfont/layout', 644)

for file in os.listdir('./icons'):
	install ('icons/' + file, '/share/birdfont/icons', 644)

install ('resources/linux/birdfont.desktop', '/share/applications', 644)
install ('resources/linux/birdfont.png', '/share/icons/hicolor/48x48/apps', 644)

if os.path.isfile ('build/bin/birdfont'):
	install ('build/bin/birdfont', '/bin', 755)

install ('build/bin/birdfont-export', '/bin', 755)

libdir = '/lib'
#library
if platform.machine() == 'i386' or platform.machine() == 's390' or platform.machine() == 'ppc' or platform.machine() == 'armv7hl':
   libdir = '/lib'
if platform.machine() == 'x86_64' or platform.machine() == 's390x' or platform.machine() == 'ppc64':
   libdir = '/lib64'

if os.path.isfile ('build/bin/libbirdfont.so.' + version.SO_VERSION):
	install ('build/bin/libbirdfont.so.' + version.SO_VERSION, libdir, 644)
	install ('build/bin/libbirdfont.so', libdir, 644)
elif os.path.isfile ('build/libbirdfont.so.' + version.SO_VERSION):
	install ('build/libbirdfont.so.' + version.SO_VERSION, libdir, 644)
	install ('build/libbirdfont.so', libdir, 644)
elif os.path.isfile ('build/bin/libbirdfont.' + version.SO_VERSION + '.dylib'):
	install ('build/bin/libbirdfont.' + version.SO_VERSION + '.dylib', libdir, 644)
	install ('build/bin/libbirdfont.dylib', libdir, 644)
else:
	print ("Can not find libbirdfont.")
	exit (1)
	
#manpages
if zip_manpages:
    install ('build/birdfont.1.gz', mandir, 644)
    install ('build/birdfont-export.1.gz', mandir, 644)
else:
    install ('resources/linux/birdfont.1', mandir, 644)
    install ('resources/linux/birdfont-export.1', mandir, 644)

# translations
for lang_dir in glob.glob('build/locale/*'):
	lc = lang_dir.replace ('build/locale/', "")
	install ('build/locale/' + lc + '/LC_MESSAGES/birdfont.mo', '/share/locale/' + lc + '/LC_MESSAGES' , 644);

installed.close ()
