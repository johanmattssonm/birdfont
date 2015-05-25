#!/usr/bin/python
"""
Copyright (C) 2013 Johan Mattsson

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
"""

import glob

try:
    from scripts.run import run
except ImportError:
    from run import run

def compile_translations ():
    for f_name in glob.glob('po/*.po'):
        lang = f_name.replace ("po/", "").replace (".po", "")
        lang = lang.replace ("\\", "/")
        build_path = "build/locale/" + lang + "/LC_MESSAGES/"
        target = build_path + "birdfont.mo"
        run ("mkdir -p " + build_path);
        f_name = f_name.replace ("\\", "/")
        run ("msgfmt --output=%s %s" % (target, f_name));	
