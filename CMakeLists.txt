cmake_minimum_required(VERSION 3.12)
project( FlightSystem LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_definitions(-DPRT_PLAT_LINUXUSER)

list(APPEND CMAKE_PREFIX_PATH "${CMAKE_SOURCE_DIR}/../build/MAVSDK/install/lib/cmake/MAVSDK")

find_package(MAVSDK CONFIG REQUIRED)
find_package(Threads REQUIRED)

set(SRC
    main.cpp
)

add_executable(${PROJECT_NAME}
    ${SRC}
)

target_link_libraries(${PROJECT_NAME} PUBLIC MAVSDK::mavsdk)
