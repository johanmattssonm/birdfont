#!/bin/bash
# Copyright (C) 2012, 2013, 2014 Johan Mattsson
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

echo "Creating a release fo version $version"

if [ $# -ne 0 -a $# -ne 2] ; then
	echo "Usage: $0 branch version"
	exit 1
fi

rm -rf birdfont-$version

if [ "$1" = "" ] ; then
        echo "No branch specified, exporting master."
	git clone --depth 1 file://$rep
else
	git clone --depth 1 -b $1 file://$rep
fi

mv birdfont birdfont-$version

rm -rf birdfont-$version/.git
rm -rf birdfont-$version/.gitignore

cd birdfont-$version
./scripts/complete_translations.py -t 93 -i
cd ..

tar -cf birdfont-$version.tar birdfont-$version

xz -z birdfont-$version.tar

rm -rf ../birdfont-$version.tar.xz

mv birdfont-$version.tar.xz ../

# build it to make sure that everything was checked in
cd birdfont-$version && \
./configure && \
./scripts/linux_build.py && \
gpg --output ../../birdfont-$version.tar.xz.sig --detach-sig ../../birdfont-$version.tar.xz && \
cd .. && \
rm -rf ../export/birdfont-$version
