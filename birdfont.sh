export LD_LIBRARY_PATH="./build/libbirdfont/:$LD_LIBRARY_PATH"
PKG_PATH=$(dirname "$(readlink -f "$0")")
cd "${PKG_PATH}"
./build/birdfont/birdfont $*
