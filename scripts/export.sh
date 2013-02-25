#!/bin/bash

rep="$(pwd)"

mkdir build
cd build
mkdir -p export
cd export 

git clone --no-hardlinks --local $rep

version=$(cat ../../scripts/version.py | grep "VERSION = '" | sed -e "s:VERSION = '::" | sed "s:'.*::g")

mv birdfont birdfont-$version

rm -rf birdfont-$version/.git
rm -rf birdfont-$version/.gitignore

tar -cf birdfont-$version.tar birdfont-$version

gzip birdfont-$version.tar

mv birdfont-$version.tar.gz ../


rm -rf ../export/birdfont-$version
