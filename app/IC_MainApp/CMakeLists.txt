cmake_minimum_required(VERSION 3.16)

project(IC_MainApp VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug CACHE STRING "Build type" FORCE)
endif()

# Qt packages - GUI + WaylandCompositor
find_package(Qt5 REQUIRED COMPONENTS Core Quick Qml WaylandCompositor)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# Source files - Compositor Only
set(SOURCES
    src/main.cpp
)

# QML resources
set(QML_RESOURCES
    qml.qrc
)

# Executable
add_executable(IC_MainApp
    ${SOURCES}
    ${QML_RESOURCES}
)

target_link_libraries(IC_MainApp
    Qt5::Core
    Qt5::Quick
    Qt5::Qml
    Qt5::WaylandCompositor
)

# Install
install(TARGETS IC_MainApp
    RUNTIME DESTINATION bin
)

message(STATUS "════════════════════════════════════════════════════════════")
message(STATUS "IC_MainApp - Wayland Compositor for Instrument Cluster")
message(STATUS "Socket: wayland-2 (connects to Weston wayland-0)")
message(STATUS "════════════════════════════════════════════════════════════")
