#!/usr/bin/python
"""
Copyright (C) 2013 2014 Johan Mattsson

This library is free software; you can redistribute it and/or modify 
it under the terms of the GNU Lesser General Public License as 
published by the Free Software Foundation; either version 3 of the 
License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but 
WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
Lesser General Public License for more details.
"""

import build
from translations import compile_translations
import configfile
from run import run
import version
from optparse import OptionParser

parser = OptionParser()
parser.add_option("-p", "--prefix", dest="prefix", help="install prefix", metavar="PREFIX")
parser.add_option("-d", "--dest", dest="dest", help="install to this directory", metavar="DEST")
parser.add_option("-c", "--cc", dest="cc", help="select the C compiler", metavar="CC")
parser.add_option("-f", "--cflags", dest="cflags", help="set compiler flags", metavar="CFLAGS")
parser.add_option("-l", "--ldflags", dest="ldflags", help="set linker flags", metavar="LDFLAGS")
parser.add_option("-v", "--valac", dest="valac", help="select vala compiler", metavar="VALAC")
parser.add_option("-n", "--nogtk", dest="nogtk", help="do not compile the gtk application", metavar="NOGTK", default=False)

(options, args) = parser.parse_args()

if not options.prefix:
	options.prefix = "/opt/local"
if not options.cc:
	options.cc = "gcc"
if not options.cflags:
	options.cflags = ""
if not options.ldflags:
	options.ldflags = ""
if not options.valac:
	options.valac = "valac"

prefix = options.prefix
valac = options.valac
valaflags = ""
cc = options.cc
cflags = options.cflags
ldflags = options.ldflags

library_cflags = "-fno-common -fPIC " + cflags 
library_ldflags = options.ldflags + " " + """-dynamiclib -Wl,-headerpad_max_install_names,-undefined,dynamic_lookup,-compatibility_version,1.0,-current_version,1.0,-install_name,""" + prefix + """/lib/libbirdfont.dylib""" 

xml_library_cflags = "-fno-common -fPIC " + cflags 
xml_library_ldflags = options.ldflags + " " + """-dynamiclib -Wl,-headerpad_max_install_names,-undefined,dynamic_lookup,-compatibility_version,1.0,-current_version,1.0,-install_name,""" + prefix + """/lib/libbirdxml.dylib""" 

configfile.write_config (prefix)
compile_translations()
build.libbirdxml(prefix, cc, xml_library_cflags, xml_library_ldflags, valac, valaflags, "libbirdxml." + version.LIBBIRDXML_SO_VERSION + ".dylib", False)
build.libbirdfont(prefix, cc, library_cflags, library_ldflags, valac, valaflags, "libbirdfont." + version.SO_VERSION + ".dylib", False)
build.birdfont_autotrace(prefix, cc, cflags, ldflags, valac, valaflags, library, False)
build.birdfont_export(prefix, cc, cflags, ldflags, valac, valaflags, library, False)
build.birdfont_import(prefix, cc, cflags, ldflags, valac, valaflags, library, False)

if not options.nogtk:
	build.birdfont_gtk(prefix, cc, cflags, ldflags, valac, valaflags, library, False)

print ("Done")
