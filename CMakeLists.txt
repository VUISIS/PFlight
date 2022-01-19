cmake_minimum_required(VERSION 3.12)
project( FlightSystem LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_definitions(-DPRT_PLAT_LINUXUSER)



find_package(Threads REQUIRED)
find_package(MAVSDK REQUIRED)

set(SRC
    main.cpp
    PForeign/FlightControllerFuncs.cpp
    PForeign/FlightControllerFuncs.h
    PForeign/TimerFuncs.cpp
    PForeign/TimerFuncs.h
    PGenerated/FlightSystem.c
    PGenerated/FlightSystem.h
)

file(GLOB_RECURSE P_SRC "${CMAKE_SOURCE_DIR}/../Prt/include/*.h")

set(P_LIB
    ${CMAKE_SOURCE_DIR}/Ext/Prt/lib/libPrt_static.a 
    ${CMAKE_SOURCE_DIR}/Ext/libhandler/lib/libhandler.a
)

add_executable(${PROJECT_NAME}
    ${SRC}
    ${MAVLINK_SRC}
    ${P_SRC}
)

target_include_directories(${PROJECT_NAME} PUBLIC /usr/include/mavsdk)
target_include_directories(${PROJECT_NAME} PUBLIC ${CMAKE_SOURCE_DIR}/Ext/Prt/include)
target_include_directories(${PROJECT_NAME} PUBLIC ${CMAKE_SOURCE_DIR}/PForeign)
target_include_directories(${PROJECT_NAME} PUBLIC ${CMAKE_SOURCE_DIR}/PGenerated)

target_link_libraries(${PROJECT_NAME} PUBLIC ${P_LIB})
target_link_libraries(${PROJECT_NAME} PUBLIC Threads::Threads)
target_link_libraries(${PROJECT_NAME} PUBLIC MAVSDK::mavsdk)