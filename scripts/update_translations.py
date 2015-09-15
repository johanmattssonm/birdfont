#!/usr/bin/python3
import subprocess
import os

def task_update_translations ():
	subprocess.check_output ("xgettext --language=vala --keyword=t_ --add-comments=/ --from-code=utf-8 --output=./po/birdfont.pot ./libbirdfont/*.vala ./birdfont/*.vala ./birdfont-export/*.vala ./birdfont-autotrace/*.vala", shell=True)

	for file in os.listdir('./po'):
		if file == "birdfont.pot": continue

		try:
			if file.index ('.po') == -1: continue		
		except:
			continue

		loc = file.replace (".po", "")
		d = "./po/" + loc + ".po"

		subprocess.check_output ("wget -O build/" + loc + ".po.zip http://pootle.locamotion.org/" + loc + "/birdfont/export/zip", shell=True)
		subprocess.check_output ("unzip build/" + loc + ".po.zip", shell=True)
		subprocess.check_output ("mv " + loc + ".po " + d, shell=True)
		
		subprocess.check_output ("msgmerge " + d + " ./po/birdfont.pot > " + loc + ".po.new", shell=True)
		subprocess.check_output ("mv " + loc + ".po.new " + d, shell=True)
	
	return  {
		'actions': ['echo "done updating translations"'],
	}


task_update_translations ()
