#!/usr/bin/python
import subprocess

def run(cmd):
	process = subprocess.Popen (cmd, shell=True)
	process.communicate()[0]
	if not process.returncode == 0:
		print("Error: " + cmd)
		exit(1)
