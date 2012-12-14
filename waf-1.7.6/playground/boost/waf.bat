@echo off
rem path are automatically detected on Linux
python waf --boost-includes=c:\boost_1_45_0 --boost-libs=c:\boost_1_45_0\stage\lib %1 %2 %3
