# PFlight 

![Ubuntu Build Status](https://github.com/VUISIS/PFlight/actions/workflows/ubuntuci.yml/badge.svg)


&nbsp;&nbsp;&nbsp;&nbsp;The field of robotics is ever growing with state spaces exploding due to their complexity.  With increasing complexity and the asynchronous nature of modern programs, comes the demand for more robust testing.  Current unit testing methods only cover a portion of code, do not efficiently search the entire state space, and often leave interleavings due to concurrency untested.  The P programming language is a modeling language and set of associated tools aimed at helping to create modular and safe distributed systems.

&nbsp;&nbsp;&nbsp;&nbsp;P is a state machine based programming language for modeling and specifying complex distributed systems. P allows programmers to model their system as a collection of communicating state machines. P supports several backend analysis engines such as model checking and symbolic execution. P can be systematically tested and compiled into executable code. Combining P with MavSDK, which is a collection of libraries to interface with the MAVLink drone messaging framework, creates a powerful simulation and testing environment for drone robotics systems. MavSDK can manage one or more vehicles via MAVLink. MavSDK communicates with the PX4 flight stack and all testing is done against PX4. Coupled with QGroundControl, a full simulation environment can be set up to test a distributed drone system before real-world deployment.

<img src="./Res/DirectedGraph.png?raw=true" width="640" height="480">

State machine of a drone using MAVSDK and the P programming language.
# Prerequisites

    MAVSDK 1.4.4
    VUISIS/P 1.1.4
    DOTNET 3.1

# Build

Clone Repo

    git clone git@github.com:VUISIS/PFlight.git --recursive

## Ubuntu 20.04:

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

    dotnet tool install --global P --version 1.1.4
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
    
Install Python3 Future 

    pip3 install future
    
    Note: Install globally. May need sudo.

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
    docker run --rm -it --env PX4_HOME_LAT=36.144809502492656 --env PX4_HOME_LON=-86.79316508433672 --env PX4_HOME_ALT=5.0 jonasvautherin/px4-gazebo-headless:1.12.1

    Run FlightSystem 
    build/FlightSystem/FlightSystem
    
Running With Docker

    # Pull the image
    docker pull saj122/pflight:quadrotor

    # Launch QGroundControl

    # Pull the jonasvautherin/px4-gazebo-headless:1.12.1 image and run it
    docker run --rm -it —network host --env PX4_HOME_LAT=36.144809502492656 --env PX4_HOME_LON=-86.79316508433672 --env PX4_HOME_ALT=5.0 jonasvautherin/px4-gazebo-headless:1.12.1 <MAIN_IP_ADDRESS> 127.0.0.1

    # Pull saj122/pflight:quadrotor image and run it
    # Omit the —platform linux/amd64 flag if running on a x86_64 system.
    docker run -it --rm --name flight_sim -w /PFlight/build/FlightSystem --network host --platform linux/amd64 saj122/pflight:quadrotor FlightSystem
