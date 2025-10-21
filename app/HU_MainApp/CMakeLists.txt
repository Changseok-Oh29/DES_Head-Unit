cmake_minimum_required(VERSION 3.16)

project(HU_MainApp VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Debug CACHE STRING "Build type" FORCE)
endif()

# Qt packages
find_package(Qt5 REQUIRED COMPONENTS Core Quick Qml Multimedia Network)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# ═══════════════════════════════════════════════════════════════════
# Source files - HU_MainApp (UI Integration Only)
# ═══════════════════════════════════════════════════════════════════
# NOTE: Manager 파일들은 각 프로세스 폴더에 있습니다:
#   - MediaApp/mediamanager.h/cpp
#   - GearApp/gearmanager.h/cpp, ipcmanager.h/cpp
#   - AmbientApp/ambientmanager.h/cpp
#
# TEMPORARY: vsomeip 통합 전까지 Manager 소스를 빌드에 포함
#            (각 프로세스에서 직접 참조)
#
# TODO: vsomeip 통합 시 Proxy 클래스로 교체:
#   - proxies/MediaProxy.h/cpp
#   - proxies/GearProxy.h/cpp
#   - proxies/AmbientProxy.h/cpp
# ═══════════════════════════════════════════════════════════════════

set(SOURCES
    src/main.cpp

    # TEMPORARY: Manager 소스 포함 (vsomeip 전까지)
    ../MediaApp/src/mediamanager.cpp
    ../GearApp/src/gearmanager.cpp
    ../AmbientApp/src/ambientmanager.cpp
    ../GearApp/src/ipcmanager.cpp

    # TODO: vsomeip 통합 시 아래로 교체
    # proxies/MediaProxy.cpp
    # proxies/GearProxy.cpp
    # proxies/AmbientProxy.cpp
)

set(HEADERS
    # TEMPORARY: Manager 헤더 포함 (vsomeip 전까지)
    ../MediaApp/src/mediamanager.h
    ../GearApp/src/gearmanager.h
    ../AmbientApp/src/ambientmanager.h
    ../GearApp/src/ipcmanager.h

    # TODO: vsomeip 통합 시 아래로 교체
    # proxies/MediaProxy.h
    # proxies/GearProxy.h
    # proxies/AmbientProxy.h
)

# QML resources
set(QML_RESOURCES
    qml.qrc
)

# Executable
add_executable(HU_MainApp
    ${SOURCES}
    ${HEADERS}
    ${QML_RESOURCES}
)

target_link_libraries(HU_MainApp
    Qt5::Core
    Qt5::Quick
    Qt5::Qml
    Qt5::Multimedia
    Qt5::Network
)

# Install
install(TARGETS HU_MainApp
    RUNTIME DESTINATION bin
)
