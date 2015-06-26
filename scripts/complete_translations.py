#!/usr/bin/python3
"""
Copyright (C) 2015 Johan Mattsson
License: LGPL
"""

import glob
from optparse import OptionParser

try:
    from scripts.run import run
except ImportError:
    from run import run
    
def completeness (pofile):
    """ Returns the completeness of the translation in percent """
    with open (pofile, 'r', encoding='utf-8') as f:
        content = f.readlines ()

    translated = 0.0
    untranslated = 0.0
    msg = ""
    original = ""
    for line in content:
        if line.startswith ("#"):
            continue
        if line.strip () == "":
            continue
        if line.startswith ("msgid"):
            if not original == "msgstr \"\"":
                if msg.strip () == "" and not original.strip () == "":
                    untranslated = untranslated + 1
                else:
                    translated = translated + 1
            original = line
            msg = ""
        if line.startswith ("msgstr") or line.startswith ("\""):
            msg += line.replace ("msgstr", "").replace ("\"", "")
        
    if msg == "" and not original == "":
        untranslated = untranslated + 1
    else:
        translated = translated + 1
        
    total = translated + untranslated
    
    if total == 0:
        return 0
    
    return (translated / total) * 100;
   
   
parser = OptionParser()
parser.add_option("-t", "--threshold", dest="threshold", help="completeness threshold in percens", metavar="THRESHOLD")
parser.add_option("-i", "--incomplete", dest="incomplete", action="store_true", default=False, help="move incomplete translations to the folder for incomplete translations", metavar="MOVE_INCOMPLETE")
parser.add_option("-r", "--remove-compiled", dest="compiled", action="store_true", default=False, help="remove compiled incomplete translations", metavar="MOVE_COMPILED_INCOMPLETE")
(options, args) = parser.parse_args()

if not options.threshold:
    for pofile in glob.glob('po/*.po'):
        completed = completeness (pofile)
        print (pofile + " " + str (completed) + "%")
elif options.compiled:
    for pofile in glob.glob('po/*.po'):
        completed = completeness (pofile)
        podir = pofile.replace ("po/", "")
        podir = podir.replace (".po", "")
        podir = podir.replace ("\\", "/")
        if completed >= float (options.threshold):
            print ("Releasing " + podir)
        else:
            print ("Removing incomplete translation " + podir)
            run ("mkdir -p build/incomplete")
            run ("mv build/locale/" + podir + " build/incomplete/") 
elif options.incomplete:
    for pofile in glob.glob('po/*.po'):
        completed = completeness (pofile)
        if completed >= float (options.threshold):
            print ("Releasing " + pofile)
        else:
            print ("Moving incomplete translation " + pofile + " to po/incomplete/")
            run ("mkdir -p po/incomplete")
            run ("mv " + pofile + " po/incomplete/") 
else:
    for pofile in glob.glob('po/*.po'):
        completed = completeness (pofile)
        if completed >= float (options.threshold):
            print (pofile)
