#!/usr/bin/python

import os
import shutil
import subprocess
import sys

def run(cmd):
	process = subprocess.Popen (cmd, shell=True)
	process.communicate()[0]
	if not process.returncode == 0:
		print("Error: " + cmd)
		exit(1)
		
def create_dmg ():
	run("rm -rf build/mac/birdfont.dmg")	
	run("hdiutil create -megabytes 55 -fs HFS+ -volname birdfont build/mac/birdfont")
	# run("cp -r build/mac/birdfont.app /Volumes/birdfont/")
	print ("Copy the files with Finder, we don't know the path here.")

create_dmg ()