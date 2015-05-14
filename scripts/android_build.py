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

prefix = ""
valac = "valac"
valaflags = "--define ANDROID --vapidir=/opt/birdfont/include --vapidir=./ --pkg android"
cc = ""
cflags = ""
ldflags = ""
library_cflags = ""
library_ldflags = ""
library = "libbirdfont.so" 

configfile.write_config (prefix)
compile_translations()
build.libbirdgems(prefix, cc, cflags, library_ldflags, valac, valaflags, library)
build.libbirdxml(prefix, cc, cflags, library_ldflags, valac, valaflags, library)
build.libbirdfont(prefix, cc, cflags, library_ldflags, valac, valaflags, library)
run ("mkdir -p build/jni");
run ("cp scripts/Android.mk build/jni/");
run ("cp scripts/Application.mk build/jni");
run ("cp build/libbirdfont/*.c build/jni/");
run ("cd build/jni && ndk-build");

print ("Done")
