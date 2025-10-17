cmake_minimum_required(VERSION 3.16)
project(DesignApp VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Qt5 패키지 모두 찾기 (DBus 추가)
find_package(Qt5 REQUIRED COMPONENTS
    Core
    Gui
    Widgets
    Qml
    Quick
    QuickControls2
    SerialPort
    Network
    QmlModels
    DBus               # <--- Qt DBus 모듈 추가
)

# 자동 moc/rcc/ui 비활성화 (수동 관리)
set(CMAKE_AUTOMOC OFF)
set(CMAKE_AUTORCC OFF)
set(CMAKE_AUTOUIC OFF)

# moc 파일 수동 생성 예 (caninterface.h)
add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/moc_caninterface.cpp
    COMMAND /usr/bin/moc
        -DQT_CORE_LIB
        -DQT_GUI_LIB
        -DQT_NETWORK_LIB
        -DQT_QMLMODELS_LIB
        -DQT_QML_LIB
        -DQT_QUICK_LIB
        -DQT_SERIALPORT_LIB
        -I${CMAKE_SYSROOT}/usr/include/aarch64-linux-gnu/qt5
        -I${CMAKE_SYSROOT}/usr/include/aarch64-linux-gnu/qt5/QtCore
        -I${CMAKE_SYSROOT}/usr/include/aarch64-linux-gnu/qt5/QtQuick
        -I${CMAKE_SYSROOT}/usr/include/aarch64-linux-gnu/qt5/QtQmlModels
        -I${CMAKE_SYSROOT}/usr/include/aarch64-linux-gnu/qt5/QtQml
        -I${CMAKE_SYSROOT}/usr/include/aarch64-linux-gnu/qt5/QtNetwork
        -I${CMAKE_SYSROOT}/usr/include/aarch64-linux-gnu/qt5/QtGui
        -I${CMAKE_SYSROOT}/usr/include/aarch64-linux-gnu/qt5/QtSerialPort
        -I${CMAKE_CURRENT_SOURCE_DIR}
        -o ${CMAKE_CURRENT_BINARY_DIR}/moc_caninterface.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/App/caninterface.h
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/App/caninterface.h
    COMMENT "Generating moc_caninterface.cpp"
)

# moc 파일 수동 생성 추가 (dbusreceiver.h)
add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/moc_dbusreceiver.cpp
    COMMAND /usr/bin/moc
        -DQT_CORE_LIB
        -DQT_GUI_LIB
        -DQT_NETWORK_LIB
        -DQT_QMLMODELS_LIB
        -DQT_QML_LIB
        -DQT_QUICK_LIB
        -DQT_SERIALPORT_LIB
        -I${CMAKE_SYSROOT}/usr/include/aarch64-linux-gnu/qt5
        -I${CMAKE_SYSROOT}/usr/include/aarch64-linux-gnu/qt5/QtCore
        -I${CMAKE_SYSROOT}/usr/include/aarch64-linux-gnu/qt5/QtQuick
        -I${CMAKE_SYSROOT}/usr/include/aarch64-linux-gnu/qt5/QtQmlModels
        -I${CMAKE_SYSROOT}/usr/include/aarch64-linux-gnu/qt5/QtQml
        -I${CMAKE_SYSROOT}/usr/include/aarch64-linux-gnu/qt5/QtNetwork
        -I${CMAKE_SYSROOT}/usr/include/aarch64-linux-gnu/qt5/QtGui
        -I${CMAKE_SYSROOT}/usr/include/aarch64-linux-gnu/qt5/QtSerialPort
        -I${CMAKE_CURRENT_SOURCE_DIR}
        -o ${CMAKE_CURRENT_BINARY_DIR}/moc_dbusreceiver.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/App/dbusreceiver.h
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/App/dbusreceiver.h
    COMMENT "Generating moc_dbusreceiver.cpp"
)

# rcc 파일 수동 처리 (app.qrc 포함)
add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/qrc_app.cpp
    COMMAND /usr/bin/rcc
        -name app
        -o ${CMAKE_CURRENT_BINARY_DIR}/qrc_app.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/App.qrc
    DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/App.qrc
    COMMENT "Generating qrc_app.cpp"
)

# 리소스 변수 설정
set(QML_RESOURCES ${CMAKE_CURRENT_BINARY_DIR}/qrc_app.cpp)

# 소스 파일 모음 (moc_dbusreceiver.cpp 추가!)
set(SOURCES
    App/main.cpp
    App/caninterface.cpp
    App/dbusreceiver.cpp                   # dbusreceiver.cpp 소스 추가
    ${CMAKE_CURRENT_BINARY_DIR}/moc_caninterface.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/moc_dbusreceiver.cpp  # moc_dbusreceiver.cpp 추가
    ${QML_RESOURCES}
)

add_executable(${PROJECT_NAME} ${SOURCES}
    App/caninterface.h
    App/dbusreceiver.h                     # 헤더파일 추가
)

target_include_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}
)

target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt5::Core
    Qt5::Gui
    Qt5::Widgets
    Qt5::Quick
    Qt5::Qml
    Qt5::QuickControls2
    Qt5::SerialPort
    Qt5::Network
    Qt5::QmlModels
    Qt5::DBus                # <--- Qt DBus 모듈 링크 추가
)

# 컴파일 경고 옵션
if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    target_compile_options(${PROJECT_NAME} PRIVATE -Wall -Wextra -Wpedantic)
endif()

# install 설정
install(TARGETS ${PROJECT_NAME}
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
