#!/usr/bin/env bash
set -e

# rm -rf build
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
ninja -C build
./build/jankk
