cmake_minimum_required(VERSION 3.16)
project(VehicleControlECU_Mock)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)

find_package(Qt5 REQUIRED COMPONENTS Core)
find_package(CommonAPI 3.2.0 REQUIRED)
find_package(CommonAPI-SomeIP 3.2.0 REQUIRED)
find_package(vsomeip3 REQUIRED)

set(GEN_DIR /home/leo/SEA-ME/DES_Head-Unit/commonapi/generated)

include_directories(
    ${GEN_DIR}/core
    ${GEN_DIR}/someip
)

add_executable(VehicleControlECU_Mock
    ../src/main_mock.cpp
    ${GEN_DIR}/someip/v1/vehiclecontrol/VehicleControlSomeIPStubAdapter.cpp
    ${GEN_DIR}/someip/v1/vehiclecontrol/VehicleControlSomeIPDeployment.cpp
)

target_link_libraries(VehicleControlECU_Mock
    Qt5::Core
    CommonAPI
    CommonAPI-SomeIP
    vsomeip3
)
