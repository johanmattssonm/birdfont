#!/usr/bin/python
"""
Copyright (C) 2013 Johan Mattsson

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

prefix = "${DESTDIR}${PREFIX}"
valac = "valac"
valaflags = ""
cc = "gcc"
cflags = ""
ldflags = ""
library_cflags = ""
library_ldflags= "";
library = "libbirdfont.so." + version.SO_VERSION

configfile.write_config (prefix)
compile_translations()
build.libbirdfont(prefix, cc, cflags, library_ldflags, valac, valaflags, library)
build.birdfont_export(prefix, cc, cflags, ldflags, valac, valaflags, library)
build.birdfont_import(prefix, cc, cflags, ldflags, valac, valaflags, library)
build.birdfont_gtk(prefix, cc, cflags, ldflags, valac, valaflags, library)

print ("Done")
