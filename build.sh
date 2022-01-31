#!/bin/bash

# Build third party libraries.

cd Ext/MAVSDK
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=../../build/MAVSDK/install -B../../build/MAVSDK -H.
cmake --build ../../build/MAVSDK --target install

cd ../P/Src
cmake -DCMAKE_INSTALL_PREFIX=../../../build/P/install -B../../../build/P -H.
cmake --build ../../../build/P 

# Build flight system

cd ../../..
mkdir -p build/FlightSystem
cd build/FlightSystem
cmake ../../C
make -j$(nproc --all)