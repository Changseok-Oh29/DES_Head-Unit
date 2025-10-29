cmake_minimum_required(VERSION 3.16)

project(AmbientApp VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug CACHE STRING "Build type" FORCE)
endif()

# RPATH 설정 (vsomeip, CommonAPI 라이브러리 경로)
set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH};/home/seam/DES_Head-Unit/install_folder")
set(CMAKE_INSTALL_RPATH "/home/seam/DES_Head-Unit/install_folder/lib")
set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--disable-new-dtags")

# Qt packages
find_package(Qt5 REQUIRED COMPONENTS Core Network Quick Qml)

# CommonAPI and vsomeip packages
find_package(CommonAPI 3.2.0 REQUIRED)
find_package(CommonAPI-SomeIP 3.2.0 REQUIRED)
find_package(vsomeip3 3.1.0 REQUIRED)
find_package(Boost 1.74 REQUIRED COMPONENTS system thread filesystem)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# Include generated code directories
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/../../commonapi/generated/core
    ${CMAKE_CURRENT_SOURCE_DIR}/../../commonapi/generated/someip
)

# Generated CommonAPI sources
set(GENERATED_SOURCES
    ../../commonapi/generated/someip/v1/mediacontrol/MediaControlSomeIPProxy.cpp
    ../../commonapi/generated/someip/v1/mediacontrol/MediaControlSomeIPStubAdapter.cpp
    ../../commonapi/generated/someip/v1/mediacontrol/MediaControlSomeIPDeployment.cpp
)

# Source files
set(SOURCES
    src/main.cpp
    src/ambientmanager.cpp
    src/MediaControlClient.cpp
    ${GENERATED_SOURCES}
)

set(HEADERS
    src/ambientmanager.h
    src/MediaControlClient.h
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
    CommonAPI
    CommonAPI-SomeIP
    vsomeip3
    ${Boost_LIBRARIES}
)

# Install
install(TARGETS AmbientApp
    RUNTIME DESTINATION bin
)
