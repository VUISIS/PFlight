# PFlight 

![Ubuntu Build Status](https://github.com/VUISIS/PFlight/actions/workflows/ubuntuci.yml/badge.svg) ![Mac Build Status](https://github.com/VUISIS/PFlight/actions/workflows/macci.yml/badge.svg) ![Windows Build Status](https://github.com/VUISIS/PFlight/actions/workflows/windowsci.yml/badge.svg)


&nbsp;&nbsp;&nbsp;&nbsp;The field of robotics is ever growing with state spaces exploding due to their complexity.  With increasing complexity and the asynchronous nature of modern programs, comes the demand for more robust testing.  Current unit testing methods only cover a portion of code, do not efficiently search the entire state space, and often leave interleavings due to concurrency untested.  The P programming language is a modeling language and set of associated tools aimed at helping to create modular and safe distributed systems.

&nbsp;&nbsp;&nbsp;&nbsp;P is a state machine based programming language for modeling and specifying complex distributed systems. P allows programmers to model their system as a collection of communicating state machines. P supports several backend analysis engines such as model checking and symbolic execution. P can be systematically tested and compiled into executable code. Combining P with MavSDK, which is a collection of libraries to interface with the MAVLink drone messaging framework, creates a powerful simulation and testing environment for drone robotics systems. MavSDK can manage one or more vehicles via MAVLink. MavSDK communicates with the PX4 flight stack and all testing is done against PX4. Coupled with QGroundControl, a full simulation environment can be set up to test a distributed drone system before real-world deployment.

<img src="./Res/DirectedGraph.png?raw=true" width="640" height="480">

State machine of a drone using MAVSDK and the P programming language.
# Build

Clone Repo

    git clone git@github.com:VUISIS/PFlight.git --recursive

## Ubuntu: Recommended

Install Dotnet

    wget https://packages.microsoft.com/config/ubuntu/21.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb
    rm packages-microsoft-prod.deb

    sudo apt-get update; \
    sudo apt-get install -y apt-transport-https && \
    sudo apt-get update && \
    sudo apt-get install -y dotnet-sdk-3.1

Install Java

    sudo apt install default-jre

Install P & Coyote

    dotnet tool install --global P --version 1.4.0
    dotnet tool install --global Microsoft.Coyote.CLI --version 1.0.5

Build P C# Program

    cd CSharp
    pc -proj:FlightSystem.pproj

Run Test Program Cases

    coyote test ./POutput/netcoreapp3.1/FlightSystem.dll -m PImplementation.CheckDroneState.Execute -i 1 -v

    coyote test ./POutput/netcoreapp3.1/FlightSystem.dll -m PImplementation.FailDroneState.Execute -i 1 -v

Build P C Program

    cd C
    pc -proj:FlightSystem.pproj

Install CMake

    sudo apt install cmake

Build MavSDK

    cd Ext/MAVSDK
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=../../build/MAVSDK/install -B../../build/MAVSDK -H.
    cmake --build ../../build/MAVSDK --target install

Build P C Static Library

    cd Ext/P/Src
    cmake -DCMAKE_INSTALL_PREFIX=../../../build/P/install -B../../../build/P -H.
    cmake --build ../../../build/P 

Build FlightSystem C Program

    mkdir -p build/FlightSystem
    cd build/FlightSystem
    cmake -DCMAKE_PREFIX_PATH=../MAVSDK/install/lib/cmake/MAVSDK ../../C
    make -j$(nproc --all)

Running Simulation

    Install Docker 
    https://docs.docker.com/engine/install/ubuntu/

    Install & Run QGroundControl 
    https://docs.qgroundcontrol.com/master/en/getting_started/download_and_install.html

    Run PX4 Docker
    docker run --rm -it --env PX4_HOME_LAT=36.144809502492656 --env PX4_HOME_LON=-86.79316508433672 --env PX4_HOME_ALT=5.0 jonasvautherin/px4-gazebo-headless:v1.12.1

    Run FlightSystem 
    build/FlightSystem/FlightSystem

## Mac OS:

Install Homebrew

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

Install Dotnet

    brew tap isen-ng/dotnet-sdk-versions
    brew install --cask dotnet-sdk3-1-400

Install Java

    brew install java

Install P & Coyote

    dotnet tool install --global P --version 1.4.0
    dotnet tool install --global Microsoft.Coyote.CLI --version 1.0.5

Build P C# Program

    cd CSharp
    pc -proj:FlightSystem.pproj

Run Test Program Cases

    coyote test ./POutput/netcoreapp3.1/FlightSystem.dll -m PImplementation.CheckDroneState.Execute -i 1 -v

    coyote test ./POutput/netcoreapp3.1/FlightSystem.dll -m PImplementation.FailDroneState.Execute -i 1 -v

Build P C Program

    cd C
    pc -proj:FlightSystem.pproj

Install CMake

    brew install cmake

Build MavSDK

    cd Ext/MAVSDK
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=../../build/MAVSDK/install -B../../build/MAVSDK -H.
    cmake --build ../../build/MAVSDK --target install

Build P C Static Library

    cd Ext/P/Src
    cmake -DCMAKE_INSTALL_PREFIX=../../../build/P/install -B../../../build/P -H.
    cmake --build ../../../build/P 

Build FlightSystem C Program

    mkdir -p build/FlightSystem
    cd build/FlightSystem
    cmake -DCMAKE_PREFIX_PATH=../MAVSDK/install/lib/cmake/MAVSDK ../../C
    make -j$(nproc --all)

Running Simulation

    Install Docker 
    https://docs.docker.com/desktop/mac/install/

    Install & Run QGroundControl 
    https://docs.qgroundcontrol.com/master/en/getting_started/download_and_install.html

    Run PX4 Docker
    docker run --rm -it --env PX4_HOME_LAT=36.144809502492656 --env PX4_HOME_LON=-86.79316508433672 --env PX4_HOME_ALT=5.0 jonasvautherin/px4-gazebo-headless:v1.12.1

    Run FlightSystem 
    build/FlightSystem/FlightSystem

## Windows:

Install Dotnet

    https://dotnet.microsoft.com/en-us/download/dotnet/thank-you/sdk-3.1.412-windows-x64-installer

Install Java

    https://www.java.com/en/download/help/windows_manual_download.html

Install P & Coyote

    dotnet tool install --global P --version 1.4.0
    dotnet tool install --global Microsoft.Coyote.CLI --version 1.0.5

Build P C# Program

    cd CSharp
    pc -proj:FlightSystem.pproj

Run Test Program Cases

    coyote test ./POutput/netcoreapp3.1/FlightSystem.dll -m PImplementation.CheckDroneState.Execute -i 1 -v

    coyote test ./POutput/netcoreapp3.1/FlightSystem.dll -m PImplementation.FailDroneState.Execute -i 1 -v

Build P C Program

    cd C
    pc -proj:FlightSystem.pproj

Download & Install CMake

    https://cmake.org/download/

Build MavSDK

    cd Ext/MAVSDK
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=../../build/MAVSDK/install -B../../build/MAVSDK -H.
    cmake --build ../../build/MAVSDK --target install

Build P C Static Library

    cd Ext/P/Src
    cmake -DCMAKE_INSTALL_PREFIX=../../../build/P/install -B../../../build/P -H.
    cmake --build ../../../build/P 

Build FlightSystem C Program

    mkdir -p build/FlightSystem
    cd build/FlightSystem
    cmake -DCMAKE_PREFIX_PATH=../MAVSDK/install/lib/cmake/MAVSDK ../../C
    make -j$(nproc --all)

Running Simulation

    Install Docker 
    https://docs.docker.com/desktop/windows/install/

    Install & Run QGroundControl 
    https://docs.qgroundcontrol.com/master/en/getting_started/download_and_install.html

    Run PX4 Docker
    docker run --rm -it --env PX4_HOME_LAT=36.144809502492656 --env PX4_HOME_LON=-86.79316508433672 --env PX4_HOME_ALT=5.0 jonasvautherin/px4-gazebo-headless:v1.12.1

    Run FlightSystem 
    build/FlightSystem/FlightSystem