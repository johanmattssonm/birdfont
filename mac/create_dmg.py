#!/usr/bin/python

import os
import shutil
import subprocess
import sys

sys.path.append('./')
import version

def run(cmd):
	process = subprocess.Popen (cmd, shell=True)
	process.communicate()[0]
	if not process.returncode == 0:
		print("Error: " + cmd)
		exit(1)
		
def create_dmg ():
	run("rm -rf build/mac/birdfont-" + version.VERSION + ".dmg")	
	run("hdiutil create -megabytes 79 -fs HFS+ -volname birdfont build/mac/birdfont-" + version.VERSION)
	# run("cp -r build/mac/birdfont.app /Volumes/birdfont/")
	print ("Copy the files with Finder, we don't know the path here.")

create_dmg ()
