
cmake_minimum_required(VERSION 3.16)

project(IC_app VERSION 1.0 LANGUAGES CXX)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(QT NAMES Qt5 Qt6 REQUIRED COMPONENTS Core Widgets Quick Network DBus)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core Widgets Quick Network DBus)

set(PROJECT_SOURCES
        main.cpp
        caninterface.cpp
        caninterface.h
        dbusreceiver.cpp
        dbusreceiver.h
        App.qrc
)

if(${QT_VERSION_MAJOR} GREATER_EQUAL 6)
    qt_add_executable(IC_app
        MANUAL_FINALIZATION
        ${PROJECT_SOURCES}
    )
else()
    add_executable(IC_app
        ${PROJECT_SOURCES}
    )
endif()

target_link_libraries(IC_app
    PRIVATE Qt${QT_VERSION_MAJOR}::Core 
            Qt${QT_VERSION_MAJOR}::Widgets 
            Qt${QT_VERSION_MAJOR}::Quick 
            Qt${QT_VERSION_MAJOR}::Network
            Qt${QT_VERSION_MAJOR}::DBus)

if(${QT_VERSION} VERSION_LESS 6.1.0)
  set(BUNDLE_ID_OPTION MACOSX_BUNDLE_GUI_IDENTIFIER com.example.IC_app)
endif()
set_target_properties(IC_app PROPERTIES
    ${BUNDLE_ID_OPTION}
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

include(GNUInstallDirs)
install(TARGETS IC_app
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR})

if(QT_VERSION_MAJOR EQUAL 6)
    qt_import_qml_plugins(IC_app)
    qt_finalize_executable(IC_app)
endif()