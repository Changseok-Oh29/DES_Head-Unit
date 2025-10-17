cmake_minimum_required(VERSION 3.10)
project(HelloWorld VERSION 1.0)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find packages
find_package(CommonAPI REQUIRED)
find_package(CommonAPI-SomeIP REQUIRED)
find_package(vsomeip3 REQUIRED)

# Include directories
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/src-gen/core
    ${CMAKE_CURRENT_SOURCE_DIR}/src-gen/someip
)

# Add generated source files
set(GENERATED_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/src-gen/someip/v1/commonapi/HelloWorldSomeIPProxy.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/src-gen/someip/v1/commonapi/HelloWorldSomeIPStubAdapter.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/src-gen/someip/v1/commonapi/HelloWorldSomeIPDeployment.cpp
)

# HelloWorld Service
add_executable(HelloWorldService
    HelloWorldService.cpp
    HelloWorldStubImpl.cpp
    ${GENERATED_SOURCES}
)

target_link_libraries(HelloWorldService
    CommonAPI
    CommonAPI-SomeIP
    vsomeip3
)

# HelloWorld Client
add_executable(HelloWorldClient
    HelloWorldClient.cpp
    ${GENERATED_SOURCES}
)

target_link_libraries(HelloWorldClient
    CommonAPI
    CommonAPI-SomeIP
    vsomeip3
)
