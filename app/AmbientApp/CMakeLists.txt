cmake_minimum_required(VERSION 3.16)

project(AmbientApp VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug CACHE STRING "Build type" FORCE)
endif()

# Qt packages
find_package(Qt5 REQUIRED COMPONENTS Core Network Quick Qml)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# Source files
set(SOURCES
    src/main.cpp
    src/ambientmanager.cpp
)

set(HEADERS
    src/ambientmanager.h
)

# QML resources
set(QML_RESOURCES
    qml.qrc
)

# Executable
add_executable(AmbientApp
    ${SOURCES}
    ${HEADERS}
    ${QML_RESOURCES}
)

target_link_libraries(AmbientApp
    Qt5::Core
    Qt5::Network
    Qt5::Quick
    Qt5::Qml
)

# Install
install(TARGETS AmbientApp
    RUNTIME DESTINATION bin
)
