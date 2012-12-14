#! /usr/bin/env python

"""
example of an ill-behaving compiler
* the output files cannot be known in advance
* the output file names are written to stdout
"""

import sys, os

def write_file(filename, contents):
	a_file = None
	try:
		a_file = open(filename, 'w')
		a_file.write(contents)
	finally:
		if a_file:
			a_file.close()

name = sys.argv[1]
file = open(name, 'r')
txt = file.read()
file.close()

lst = txt.split('\n')
for line in lst:
	source_filename = line.strip()
	if not source_filename: continue
	(dirs, name) = os.path.split(source_filename)
	try:
		os.makedirs(dirs)
	except:
		pass

	header_filename = os.path.splitext(source_filename)[0] + '.h'
	varname = name.replace('.', '_')
	write_file(header_filename, 'int %s=4;\n' % varname)
	write_file(source_filename, '#include "%s"\nint get_%s() {return %s;}\n' % (os.path.split(header_filename)[1], varname, varname))

	print (source_filename)
	print (header_filename)

