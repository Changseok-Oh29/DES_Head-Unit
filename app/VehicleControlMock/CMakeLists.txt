cmake_minimum_required(VERSION 3.16)
project(VehicleControlMock VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ════════════════════════════════════════════════════════════
# 배포 환경별 경로 설정 (환경변수 우선)
# ════════════════════════════════════════════════════════════
if(DEFINED ENV{DEPLOY_PREFIX})
    set(INSTALL_PREFIX $ENV{DEPLOY_PREFIX})
    message(STATUS "Using DEPLOY_PREFIX from environment: ${INSTALL_PREFIX}")
else()
    set(INSTALL_PREFIX "${CMAKE_SOURCE_DIR}/../../install_folder")
    message(STATUS "Using default DEPLOY_PREFIX: ${INSTALL_PREFIX}")
endif()

# RPATH 설정 (vsomeip, CommonAPI 라이브러리 경로)
set(CMAKE_PREFIX_PATH "${CMAKE_PREFIX_PATH};${INSTALL_PREFIX}")
set(CMAKE_INSTALL_RPATH "${INSTALL_PREFIX}/lib")
set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--disable-new-dtags")

# Qt5
find_package(Qt5 REQUIRED COMPONENTS Core)
set(CMAKE_AUTOMOC ON)

# CommonAPI
find_package(CommonAPI 3.2.0 REQUIRED)
find_package(CommonAPI-SomeIP 3.2.0 REQUIRED)
find_package(vsomeip3 REQUIRED)

# Generated CommonAPI code paths
if(DEFINED ENV{COMMONAPI_GEN_DIR})
    set(COMMONAPI_GEN_DIR $ENV{COMMONAPI_GEN_DIR})
    message(STATUS "Using COMMONAPI_GEN_DIR from environment: ${COMMONAPI_GEN_DIR}")
elseif(DEFINED COMMONAPI_GEN_DIR)
    message(STATUS "Using COMMONAPI_GEN_DIR from CMake argument: ${COMMONAPI_GEN_DIR}")
else()
    set(COMMONAPI_GEN_DIR ${CMAKE_SOURCE_DIR}/../../commonapi/generated)
    message(STATUS "Using default COMMONAPI_GEN_DIR: ${COMMONAPI_GEN_DIR}")
endif()

set(COMMONAPI_CORE_DIR ${COMMONAPI_GEN_DIR}/core)
set(COMMONAPI_SOMEIP_DIR ${COMMONAPI_GEN_DIR}/someip)

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${COMMONAPI_CORE_DIR}
    ${COMMONAPI_SOMEIP_DIR}
    ${COMMONAPI_INCLUDE_DIRS}
    ${COMMONAPI_SOMEIP_INCLUDE_DIRS}
)

# Source files
set(SOURCES
    src/main.cpp
    src/VehicleControlStubImpl.cpp
)

# CommonAPI generated sources
file(GLOB COMMONAPI_CORE_SOURCES
    "${COMMONAPI_CORE_DIR}/v1/vehiclecontrol/*.cpp"
)

file(GLOB COMMONAPI_SOMEIP_SOURCES
    "${COMMONAPI_SOMEIP_DIR}/v1/vehiclecontrol/*.cpp"
)

# Create executable
add_executable(${PROJECT_NAME}
    ${SOURCES}
    ${COMMONAPI_CORE_SOURCES}
    ${COMMONAPI_SOMEIP_SOURCES}
)

# Link libraries
target_link_libraries(${PROJECT_NAME}
    Qt5::Core
    CommonAPI
    CommonAPI-SomeIP
    vsomeip3
    pthread
)

# Installation
install(TARGETS ${PROJECT_NAME}
    RUNTIME DESTINATION bin
)

# Print configuration
message(STATUS "=== VehicleControlMock Configuration ===")
message(STATUS "Platform: Ubuntu (No hardware dependencies)")
message(STATUS "Qt5 Core: ${Qt5Core_VERSION}")
message(STATUS "CommonAPI: ${COMMONAPI_VERSION}")
message(STATUS "CommonAPI-SomeIP: ${COMMONAPI_SOMEIP_VERSION}")
message(STATUS "Generated code dir: ${COMMONAPI_GEN_DIR}")
message(STATUS "========================================")
