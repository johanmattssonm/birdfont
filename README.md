![Birdfont logo][birdfont]

# Birdfont - Font Editor

Birdfont is a font editor which can create vector graphics and
export SVG, EOT and TTF fonts.

    Author: Johan Mattsson and others see AUTHORS for full attribution.
    License: GNU GPL v3
    Webpage: https://birdfont.org

## Building from Source

Install vala and all required libraries, they are most likely in
packages with a -dev or -devel affix:

    valac
    python3-doit
    libxmlbird-dev
    libgee-0.8-dev
    libglib2.0-dev 
    libgtk-3-dev 
    libwebkit2gtk-4.1-dev
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

The default prefix is /usr/local. On some system is /usr the right prefix.

    ./configure --prefix=/usr
    ./build.py
     sudo ./install.py

All patches must be compiled with support for valas null pointer checks.
Configure the project with ./configure --nonnull 

## Packages

Windows and Mac binaries can be downloaded from
https://birdfont.org Many Linux distributions have packages of
Birdfont in their repositories. There are BSD packages in OpenBSD and FreeBSD.

## Logo
The logo was created by Marko Jovanovac. You can find it here:
resources/birdfont-logo.svg

[birdfont]: https://birdfont.org/images/birdfont_logo2.png "Birdfont logo"
[xmlbird]: https://birdfont.org/xmlbird.php "XML Bird – XML Parser for programs written in VALA"

#
