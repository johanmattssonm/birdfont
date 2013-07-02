#!/usr/bin/python
"""
Copyright (C) 2013 Johan Mattsson

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
"""

import os
import subprocess
import glob
from optparse import OptionParser
from run import run

def install (file, dir):
	if dest == "":
		f = prefix + dir + '/'
	else:
		f = dest + prefix + dir + '/'
		
	s = file.rfind ('/')
	if s > -1:
		f += file[s + 1:]
	else:
		f += file
	print ("install: " + file + " in " + ' ' + dest + prefix + dir + '/')
	subprocess.check_call ('install -d ' + dest + prefix + dir, shell=True)
	subprocess.check_call ('install ' + file + ' ' + dest + prefix + dir + '/', shell=True)

parser = OptionParser()
parser.add_option ("-p", "--prefix", dest="prefix", help="install prefix", metavar="PREFIX")
parser.add_option ("-d", "--dest", dest="dest", help="install to this directory", metavar="DEST")
parser.add_option ("-a", "--app", dest="app", help="install application launcher in this directory", metavar="APP")

(options, args) = parser.parse_args()

if not options.prefix:
	options.prefix = "/opt/local"

if not options.dest:
	options.dest = ""

if not options.app:
	options.app = "/Applications"

prefix = options.prefix
dest = options.dest

install ('build/bin/birdfont', '/bin')
install ('build/bin/birdfont-export', '/bin')	
install ('build/bin/libbirdfont.dylib', '/lib')

for file in os.listdir('./layout'):
	install ('layout/' + file, '/share/birdfont/layout')

for file in os.listdir('./icons'):
	install ('icons/' + file, '/share/birdfont/icons')
	
for lang_dir in glob.glob('build/locale/*'):
	lc = lang_dir.replace ('build/locale/', "")
	install ('build/locale/' + lc + '/LC_MESSAGES/birdfont.mo', '/share/locale/' + lc + '/LC_MESSAGES' );

run ("cp -R -p build/BirdFont.app " + options.app)
