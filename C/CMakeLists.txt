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
    PForeign/FlightControllerFuncs.cpp
    PForeign/FlightControllerFuncs.h
    PGenerated/FlightSystem.c
    PGenerated/FlightSystem.h
)

file(GLOB_RECURSE P_SRC "${CMAKE_SOURCE_DIR}/../Ext/P/Bld/Drops/Prt/include/*.h")

set(TINYXML_INC 
    ${CMAKE_SOURCE_DIR}/../build/MAVSDK/third_party/tinyxml2/tinyxml2/src/tinyxml2/tinyxml2.h
)

set(LIBH_SRC
    ${CMAKE_SOURCE_DIR}/../Ext/P/Bld/Drops/Prt/include/libhandler.h
)

set(P_LIB
    ${CMAKE_SOURCE_DIR}/../Ext/P/Bld/Drops/Prt/lib/libPrt_static.a
)

set(TINYXML_LIB
    ${CMAKE_SOURCE_DIR}/../build/MAVSDK/third_party/tinyxml2/tinyxml2/src/tinyxml2-build/libtinyxml2.a
)

set(LIBH_LIB
    ${CMAKE_SOURCE_DIR}/../Ext/P/Ext/libhandler/out/gcc-amd64-linux-gnu/debug/libhandler.a
)

add_executable(${PROJECT_NAME}
    ${SRC}
    ${P_SRC}
    ${TINYXML_INC}
    ${LIBH_SRC}
)

target_include_directories(${PROJECT_NAME} PUBLIC ${CMAKE_SOURCE_DIR}/../Ext/P/Bld/Drops/Prt/include)
target_include_directories(${PROJECT_NAME} PUBLIC ${CMAKE_SOURCE_DIR}/PForeign)
target_include_directories(${PROJECT_NAME} PUBLIC ${CMAKE_SOURCE_DIR}/PGenerated)

target_link_libraries(${PROJECT_NAME} PUBLIC ${P_LIB})
target_link_libraries(${PROJECT_NAME} PUBLIC Threads::Threads)
target_link_libraries(${PROJECT_NAME} PUBLIC ${LIBH_LIB})
target_link_libraries(${PROJECT_NAME} PUBLIC ${TINYXML_LIB})
target_link_libraries(${PROJECT_NAME} PUBLIC MAVSDK::mavsdk)
