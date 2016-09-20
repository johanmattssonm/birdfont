#!/bin/sh

if ! git diff --exit-code > /dev/null; then
        echo "Uncommitted changes, commit before creating the release."
        exit 1
fi

SOURCE_DIR="$(pwd)"

rm -rf $SOURCE_DIR/build/snapsource
mkdir -p $SOURCE_DIR/build/snapsource && \
cd $SOURCE_DIR/build/snapsource && \
git clone --depth=1 file:///$SOURCE_DIR birdfont && \
cd $SOURCE_DIR/build/snapsource/birdfont && \
python3 ./scripts/complete_translations.py -t 93 -i && \
cd .. && \
cd .. && \
mkdir -p setup/gui && \
cp ../resources/linux/256x256/birdfont.png setup/gui/icon.png && \
cd .. && \
./scripts/snap.py --free && \
cd build && \
snapcraft snap && \
cd .. && \
./scripts/snap.py && \
cd build && \
snapcraft snap
