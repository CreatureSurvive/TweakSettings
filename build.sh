#/bin/sh

sudo xcode-select -switch /Applications/Xcode-11.7.0.app/Contents/Developer
xcode-select --print-path
# export PREFIX=$THEOS/toolchains/Xcode11.xctoolchain/usr/bin/

make clean
make package FINALPACKAGE=1

# export -n PREFIX
sudo xcode-select -switch /Applications/Xcode-12.5.0.app/Contents/Developer
xcode-select --print-path

make clean
make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless