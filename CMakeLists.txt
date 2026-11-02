cmake_minimum_required(VERSION 3.21)
project(jankk VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick Multimedia)

qt_standard_project_setup(REQUIRES 6.5)
qt_policy(SET QTP0004 NEW)

find_path(MGBA_INCLUDE_DIR mgba/core/core.h REQUIRED)
find_library(MGBA_LIBRARY mgba REQUIRED)

set(RYU_MODULES "Shapes" CACHE STRING "" FORCE)
set(RYU_STATIC ON CACHE BOOL "" FORCE)
set(RYU_INSTALL OFF CACHE BOOL "" FORCE)
add_subdirectory(third_party/ryu)

qt_add_executable(jankk)

qt_add_qml_module(jankk
    URI Jankk
    VERSION 1.0
    RESOURCE_PREFIX "/qt/qml"
    OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/Jankk"
    NO_PLUGIN
    QML_FILES
        qml/Main.qml
    SOURCES
        src/main.cpp
        src/emu/emulator.cpp
        src/emu/emulator.h
        src/view/gbaview.cpp
        src/view/gbaview.h
)

set_target_properties(jankk PROPERTIES OUTPUT_NAME _jankk)

target_include_directories(jankk PRIVATE
    "${MGBA_INCLUDE_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/src"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/emu"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/view"
)

target_link_libraries(jankk PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::Multimedia
    Ryu::Shapes
    Ryu::Shapesplugin
    "${MGBA_LIBRARY}"
)

qt_import_qml_plugins(jankk)

qt_add_executable(headless_test src/headless_test.cpp)
target_include_directories(headless_test PRIVATE "${MGBA_INCLUDE_DIR}")
target_link_libraries(headless_test PRIVATE Qt6::Core Qt6::Gui "${MGBA_LIBRARY}")
