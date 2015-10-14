#!/usr/bin/python3

import subprocess
from os import path

from run import run

def fuzz_svg_import():
    fuzz_svg ('birdfont-test/inkscape.svg')
    fuzz_svg ('birdfont-test/illustrator.svg')

def fuzz_svg (file):
    run ("mkdir -p build/fuzz")
    run ("mkdir -p build/fuzz/bugs")
    run ("radamsa " + file + " > build/fuzz/a.svg")

    cmd = "./birdfont-test.sh SVG build/fuzz/a.svg"
    print('Running: ' + cmd)
    process = subprocess.Popen (cmd, shell=True)
    process.communicate()[0]
    if not process.returncode == 0:
        print("Error: " + cmd)
        print("A bug was found.")
        
        i = 0
        while path.isfile ('build/bugs/a_' + str(i) + '.svg'):
            i = i + 1
			
        run ('mv build/fuzz/a.svg attic/fuzz/bugs/a_' + str(i) + '.svg')

    run ("rm -f build/fuzz/a.svg")

while True:
    fuzz_svg_import ()
