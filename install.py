#!/usr/bin/python 
"""
Copyright (C) 2013 2014 Johan Mattsson

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

def getDestRoot (file, dir):
	f = dest + dir + '/'
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

def install_root (file, dir, mode):
        f = getDestRoot (file, dir)
        print ("install: " + f)
        run ('install -d ' + dest + dir)
	run ('install -m ' + `mode` + ' '   + file + ' ' + dest + dir + '/')

def link (dir, file, linkname):
	f = getDest (linkname, dir)
	print ("install link: " + f)
	run ('cd ' + dest + prefix + dir + ' && ln -sf ' + file + ' ' + linkname)
	installed.write (f + "\n")
	
if not os.path.exists ("build/configured"):
	print ("Project is not configured")
	exit (1)

parser = OptionParser()
parser.add_option ("-d", "--dest", dest="dest", help="install to this directory", metavar="DEST")
parser.add_option ("-m", "--nogzip", dest="nogzip", help="don't gzip manpages", default=False)
parser.add_option ("-n", "--manpages-directory", dest="mandir", help="put man pages in this directory under prefix")
parser.add_option ("-l", "--libdir", dest="libdir", help="path to directory for shared libraries (lib or lib64).")
parser.add_option ("-c", "--skip-command-line-tools", dest="nocli", help="don't install command line tools")
parser.add_option ("-a", "--apport", dest="apport", help="install apport scripts")

(options, args) = parser.parse_args()

if not options.dest:
	options.dest = ""

if not options.nocli:
	options.nocli = False

nogzip = options.nogzip

apport = options.apport
if apport == None:
	apport = True

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
install ('resources/icons.bf', '/share/birdfont', 644)
install ('resources/bright.theme', '/share/birdfont', 644)
install ('resources/dark.theme', '/share/birdfont', 644)
install ('resources/high_contrast.theme', '/share/birdfont', 644)
install ('resources/key_bindings.xml', '/share/birdfont', 644)
install ('resources/roboto.bf', '/share/birdfont', 644)
install ('resources/linux/birdfont_window_icon.png', '/share/birdfont', 644)
install ('resources/linux/birdfont.desktop', '/share/applications', 644)

install ('resources/linux/256x256/birdfont.png', '/share/icons/hicolor/256x256/apps', 644)
install ('resources/linux/128x128/birdfont.png', '/share/icons/hicolor/128x128/apps', 644)
install ('resources/linux/48x48/birdfont.png', '/share/icons/hicolor/48x48/apps', 644)

install ('resources/linux/birdfont.appdata.xml', '/share/appdata', 644)

if os.path.isfile ('build/bin/birdfont'):
	install ('build/bin/birdfont', '/bin', 755)

if not options.nocli:
	install ('build/bin/birdfont-autotrace', '/bin', 755)
	install ('build/bin/birdfont-export', '/bin', 755)
	install ('build/bin/birdfont-import', '/bin', 755)

#library
if not options.libdir:
	
	if platform.dist()[0] == 'Ubuntu' or platform.dist()[0] == 'Debian':
		process = subprocess.Popen(['dpkg-architecture', '-qDEB_HOST_MULTIARCH'], stdout=subprocess.PIPE)
		out, err = process.communicate()
		libdir = '/lib/' + out.rstrip ('\n')
	else:
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
	print ("Can't find libbirdfont.")
	exit (1)

if os.path.isfile ('build/bin/libbirdxml.so.' + version.LIBBIRDXML_SO_VERSION):
        install ('build/bin/libbirdxml.so.' + version.LIBBIRDXML_SO_VERSION, libdir, 644)
        link (libdir, 'libbirdxml.so.' + version.LIBBIRDXML_SO_VERSION, ' libbirdxml.so.' + version.LIBBIRDXML_SO_VERSION_MAJOR)
        link (libdir, 'libbirdxml.so.' + version.LIBBIRDXML_SO_VERSION, ' libbirdxml.so')
elif os.path.isfile ('build/libbirdxml.so.' + version.LIBBIRDXML_SO_VERSION):
        install ('build/libbirdxml.so.' + version.LIBBIRDXML_SO_VERSION, libdir, 644)
        link (libdir, 'libbirdxml.so.' + version.LIBBIRDXML_SO_VERSION, ' libbirdxml.so.' + version.LIBBIRDXML_SO_VERSION_MAJOR)
        link (libdir, 'libbirdxml.so.' + version.LIBBIRDXML_SO_VERSION, ' libbirdxml.so')
elif os.path.isfile ('build/bin/libbirdxml.' + version.LIBBIRDXML_SO_VERSION + '.dylib'):
        install ('build/bin/libbirdxml.' + version.LIBBIRDXML_SO_VERSION + '.dylib', libdir, 644)
        link (libdir, 'libbirdxml.' + version.LIBBIRDXML_SO_VERSION + '.dylib', ' libbirdxml.dylib.' + version.LIBBIRDXML_SO_VERSION_MAJOR)
        link (libdir, 'libbirdxml.' + version.LIBBIRDXML_SO_VERSION + '.dylib', ' libbirdxml.dylib')
else:
        print ("Can't find libbirdxml.")

	
#manpages

if not nogzip:
    install ('build/birdfont.1.gz', mandir, 644)

    if not options.nocli:
        install ('build/birdfont-autotrace.1.gz', mandir, 644)
        install ('build/birdfont-export.1.gz', mandir, 644)
        install ('build/birdfont-import.1.gz', mandir, 644)
else:
    install ('resources/linux/birdfont.1', mandir, 644)

    if not options.nocli:
        install ('resources/linux/birdfont-autotrace.1', mandir, 644)
        install ('resources/linux/birdfont-export.1', mandir, 644)
        install ('resources/linux/birdfont-import.1', mandir, 644)

#translations
for lang_dir in glob.glob('build/locale/*'):
	lc = lang_dir.replace ('build/locale/', "")
	install ('build/locale/' + lc + '/LC_MESSAGES/birdfont.mo', '/share/locale/' + lc + '/LC_MESSAGES' , 644);

#file type 
install ('resources/linux/birdfont.xml', '/share/mime/packages', 644)

#apport hooks
if apport:
	install ('resources/birdfont.py', '/share/apport/package-hooks', 644)
	install ('resources/source_birdfont.py', '/share/apport/package-hooks', 644)
	install_root ('resources/birdfont-crashdb.conf', '/etc/apport/crashdb.conf.d', 644)

installed.close ()
