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
prefix = ""
valac = "valac"
valaflags = ""
cc = "gcc"
cflags = "-g -Wl,-subsystem,windows "
ldflags = ""
library_ldflags= "";

import configfile
configfile.write_config (prefix)
configfile.write_compile_parameters (".\\\\", "build", "gcc", "gee-0.8", "False")

import build
from translations import compile_translations

from run import run

compile_translations()
build.libbirdgems(prefix, cc, cflags, library_ldflags, valac, valaflags, "libbirdgems.dll")
build.libbirdxml(prefix, cc, cflags, library_ldflags, valac, valaflags, "libbirdxml.dll")
build.libbirdfont(prefix, cc, cflags, library_ldflags, valac, valaflags, "libbirdfont.dll")

run ("cp build/bin/libbirdfont.dll ./")
run ("gcc -Wl,-subsystem,windows -Wl,--output-def,build/bin/libbirdfont.def,--out-implib -shared -Wl,-soname,libbirdfont.dll libbirdfont.dll")
run ("rm libbirdfont.dll")

#FIMXE
#build.birdfont_export(prefix, cc, cflags, ldflags, valac, valaflags)
#build.birdfont_import(prefix, cc, cflags, ldflags, valac, valaflags)
#build.birdfont_autotrace(prefix, cc, cflags, ldflags, valac, valaflags)

print ("Done")
