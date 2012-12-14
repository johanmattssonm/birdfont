#! /usr/bin/env python

from waflib import Context

def cnt(ctx):
	"""do something"""
	print('just a test')

Context.g_module.__dict__['cnt'] = cnt

