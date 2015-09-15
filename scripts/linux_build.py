#!/usr/bin/python
import os.path
from run import run

if not path.isfile('./build/configured'):
	run("""./configure 
			  --valac-flags="--pkg gdk-pixbuf-2.0 --pkg gtk+-3.0" \
			  --cflags="$(pkg-config --cflags gdk-pixbuf-2.0)"
			  --ldflags="$(pkg-config --libs gdk-pixbuf-2.0)""")

run('./build.py')		  
print ("Done")
