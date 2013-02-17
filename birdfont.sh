#!/bin/bash
export LD_LIBRARY_PATH="./build/:$LD_LIBRARY_PATH"
PKG_PATH=$(dirname "$(readlink -f "$0")")
cd "${PKG_PATH}"
./build/bin/birdfont "$@"
