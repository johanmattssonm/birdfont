#!/usr/bin/python

import configfile
from optparse import OptionParser

parser = OptionParser()
parser.add_option("-p", "--prefix", dest="prefix", help="install prefix", metavar="PREFIX")

(options, args) = parser.parse_args()

if not options.prefix:
	options.prefix = "/usr"

configfile.write_config (options.prefix)
