#!/usr/bin/python3

import subprocess
from os import path

from run import run

def fuzz_import():
    fuzz_bf ('birdfont-test/testfont.bf')

def fuzz_bf (file):
    run ("mkdir -p build/fuzz")
    run ("mkdir -p build/fuzz/bugs")
    run ("radamsa " + file + " > build/fuzz/font.bf")

    cmd = "./birdfont-test.sh BF build/fuzz/font.bf"
    print('Running: ' + cmd)
    process = subprocess.Popen (cmd, shell=True)
    process.communicate()[0]
    if not process.returncode == 0:
        print("Error: " + cmd)
        print("A bug was found.")
        
        i = 0
        while path.isfile ('build/bugs/font_' + str(i) + '.bf'):
            i = i + 1
			
        run ('mv build/fuzz/font.bf attic/fuzz/bugs/font_' + str(i) + '.bf')

    run ("rm -f build/fuzz/font.svg")

while True:
    fuzz_import ()
