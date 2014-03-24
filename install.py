#!/usr/bin/python 
"""
Copyright (C) 2013 Johan Mattsson

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
"""

import os
import subprocess
import glob
import platform
from optparse import OptionParser
from scripts import config
from scripts import version
from scripts.run import run

def getDest (file, dir):
	f = dest + prefix + dir + '/'
	s = file.rfind ('/')
	if s > -1:
		f += file[s + 1:]
	else:
		f += file
	return f
	
def install (file, dir, mode):
	f = getDest (file, dir)
	print ("install: " + f)
	run ('install -d ' + dest + prefix + dir)
	run ('install -m ' + `mode` + ' '   + file + ' ' + dest + prefix + dir + '/')
	installed.write (f + "\n")

def link (dir, file, linkname):
	f = getDest (linkname, dir)
	print ("install link: " + f)
	run ('cd ' + dest + prefix + dir + ' && ln -sf ' + file + ' ' + linkname)
	installed.write (f + "\n")
	
if not os.path.exists ("build/configured"):
	print ("Project is not configured")
	exit (1)

if not os.path.exists ("build/installed"):
        print ("Project is not built")
        exit (1)

parser = OptionParser()
parser.add_option ("-d", "--dest", dest="dest", help="install to this directory", metavar="DEST")
parser.add_option ("-m", "--nogzip", dest="nogzip", help="don't gzip manpages", default=False)
parser.add_option ("-n", "--manpages-directory", dest="mandir", help="put man pages in this directory under prefix")
parser.add_option ("-l", "--libdir", dest="libdir", help="path to directory for shared libraries (lib or lib64).")

(options, args) = parser.parse_args()

if not options.dest:
	options.dest = ""

nogzip = options.nogzip

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
install ('resources/linux/128x128/birdfont.png', '/share/icons/hicolor/128x128/apps', 644)
install ('resources/linux/48x48/birdfont.png', '/share/icons/hicolor/48x48/apps', 644)

if os.path.isfile ('build/bin/birdfont'):
	install ('build/bin/birdfont', '/bin', 755)

install ('build/bin/birdfont-export', '/bin', 755)

#library
if not options.libdir:
	p = platform.machine()
 	if p == 'i386' or p == 's390' or p == 'ppc' or p == 'armv7hl':
 		libdir = '/lib'
 	elif p == 'x86_64' or p == 's390x' or p == 'ppc64':
 		libdir = '/lib64'
 	else:
		libdir = '/lib'
else:
	libdir = options.libdir

if os.path.isfile ('build/bin/libbirdfont.so.' + version.SO_VERSION):
	install ('build/bin/libbirdfont.so.' + version.SO_VERSION, libdir, 644)
	link (libdir, 'libbirdfont.so.' + version.SO_VERSION, ' libbirdfont.so.' + version.SO_VERSION_MAJOR)
	link (libdir, 'libbirdfont.so.' + version.SO_VERSION, ' libbirdfont.so')
elif os.path.isfile ('build/libbirdfont.so.' + version.SO_VERSION):
	install ('build/libbirdfont.so.' + version.SO_VERSION, libdir, 644)
	link (libdir, 'libbirdfont.so.' + version.SO_VERSION, ' libbirdfont.so.' + version.SO_VERSION_MAJOR)
	link (libdir, 'libbirdfont.so.' + version.SO_VERSION, ' libbirdfont.so')
elif os.path.isfile ('build/bin/libbirdfont.' + version.SO_VERSION + '.dylib'):
	install ('build/bin/libbirdfont.' + version.SO_VERSION + '.dylib', libdir, 644)
	link (libdir, 'libbirdfont.' + version.SO_VERSION + '.dylib', ' libbirdfont.dylib.' + version.SO_VERSION_MAJOR)
	link (libdir, 'libbirdfont.' + version.SO_VERSION + '.dylib', ' libbirdfont.dylib')
else:
	print ("Can not find libbirdfont.")
	exit (1)
	
#manpages
if not nogzip:
    install ('build/birdfont.1.gz', mandir, 644)
    install ('build/birdfont-export.1.gz', mandir, 644)
else:
    install ('resources/linux/birdfont.1', mandir, 644)
    install ('resources/linux/birdfont-export.1', mandir, 644)

#translations
for lang_dir in glob.glob('build/locale/*'):
	lc = lang_dir.replace ('build/locale/', "")
	install ('build/locale/' + lc + '/LC_MESSAGES/birdfont.mo', '/share/locale/' + lc + '/LC_MESSAGES' , 644);

#file type 
install ('resources/linux/birdfont.xml', '/share/mime/packages', 644)

installed.close ()
