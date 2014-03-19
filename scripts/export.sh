#!/bin/bash
# Copyright (C) 2012, 2013 Johan Mattsson
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

rep="$(pwd)"

mkdir -p build
cd build
mkdir -p export
cd export 

version=$(cat ../../scripts/version.py | grep "VERSION = '" | grep -v "SO_VERSION" | sed -e "s:VERSION = '::" | sed "s:'.*::g")

rm -rf birdfont-$version

git clone --depth 1 --no-hardlinks --local $rep


mv birdfont birdfont-$version

rm -rf birdfont-$version/.git
rm -rf birdfont-$version/.gitignore

tar -cf birdfont-$version.tar birdfont-$version

gzip birdfont-$version.tar

rm -rf ../birdfont-$version.tar.gz

mv birdfont-$version.tar.gz ../

rm -rf ../export/birdfont-$version
