#!/usr/bin/python
import glob
from run import run

def compile_translations ():
    for f_name in glob.glob('po/*.po'):
        lang = f_name.replace ("po/", "").replace (".po", "")
        build_path = "build/locale/" + lang + "/LC_MESSAGES/"
        target = build_path + "birdfont.mo"
        run ("mkdir -p " + build_path);
        run ("msgfmt --output=%s %s" % (target, f_name));	
