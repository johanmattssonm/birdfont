#! /usr/bin/env python
# encoding: utf-8

print('→ loading the dang tool')

from waflib.Configure import conf

def options(opt):
    opt.add_option('--dang', action='store', default='', dest='dang')

@conf
def read_dang(ctx):
    ctx.start_msg('Checking for DANG')
    if ctx.options.dang:
        ctx.env.DANG = ctx.options.dang
        ctx.end_msg(ctx.env.DANG)
    else:
        ctx.end_msg('DANG is not set')

def configure(ctx):
    ctx.read_dang()
