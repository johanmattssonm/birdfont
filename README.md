![Birdfont logo][birdfont]

# Birdfont - Font Editor

Birdfont is a font editor which can create vector graphics and
export SVG, EOT and TTF fonts.

    Author: Johan Mattsson and others see AUTHORS for full attribution.
    License: GNU GPL v3
    Webpage: http://birdfont.org
    Bugtracker: http://birdfont.org/bugtracker/my_view_page.php

[![Build Status](https://travis-ci.org/johanmattssonm/birdfont.svg)]
(https://travis-ci.org/johanmattssonm/birdfont)

## Building from Source

Install vala and all required libraries, they are most likely in
packages with a -dev or -devel affix:

    valac
    python3-doit
    font-roboto
    libxmlbird-dev
    libgee-dev
    libglib2.0-dev 
    libgtk-3-dev 
    libwebkitgtk-3.0-dev 
    libnotify-dev
    libsqlite3-dev

XML Bird is available from [birdfont.org][xmlbird].

BirdFont have two build systems, one python script that builds all
binaries at once and one dependency based build system that uses
doit.

Configure, build and install with python:

    ./configure
    ./build.py
    sudo ./install.py

Configure, build and install with doit:

    ./configure
    doit3
    sudo ./install.py

The default prefix is /usr/local on Fedora should BirdFont be compiled with
/usr as prefix.

    ./configure --prefix=/usr
    ./build.py
     sudo ./install.py

All patches must be compiled with support for valas null pointer checks.
Configure the project with ./configure --nonnull 

## Packages

Windows and Mac binaries can be downloaded from
http://birdfont.org Many Linux distributions have packages of
Birdfont in their repositories. There is a BSD package in OpenBSD.

[birdfont]: http://birdfont.org/images/birdfont_logo2.png "Birdfont logo"
[xmlbird]: http://birdfont.org/xmlbird.php "XML Bird – XML Parser for programs written in VALA"

