cmake_minimum_required(VERSION 3.21)
project(jankk VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick Multimedia)

qt_standard_project_setup(REQUIRES 6.5)
qt_policy(SET QTP0004 NEW)

find_path(MGBA_INCLUDE_DIR mgba/core/core.h REQUIRED)
find_library(MGBA_LIBRARY mgba REQUIRED)

set(RYU_MODULES "Shapes;Extraa" CACHE STRING "" FORCE)
set(RYU_STATIC ON CACHE BOOL "" FORCE)
set(RYU_INSTALL OFF CACHE BOOL "" FORCE)
add_subdirectory(third_party/ryu)

set(SFX_NAMES
    nav nav_edge type delete clear select launch back exit
    error nomatch fullscreen boot coin noise_tick boom
)

set(SFX_FILES)
foreach(name IN LISTS SFX_NAMES)
    set(sfx_file "${CMAKE_CURRENT_SOURCE_DIR}/sfx/${name}.wav")
    set_source_files_properties("${sfx_file}" PROPERTIES QT_RESOURCE_ALIAS "sfx/${name}.wav")
    list(APPEND SFX_FILES "${sfx_file}")
endforeach()
set_source_files_properties("${CMAKE_CURRENT_SOURCE_DIR}/jankk.png" PROPERTIES QT_RESOURCE_ALIAS "jankk.png")
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
        src/library/gamelibrary.cpp
        src/library/gamelibrary.h
    RESOURCES
        ${SFX_FILES}
        "${CMAKE_CURRENT_SOURCE_DIR}/jankk.png"
)

set_target_properties(jankk PROPERTIES OUTPUT_NAME jankk)

target_include_directories(jankk PRIVATE
    "${MGBA_INCLUDE_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/src"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/emu"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/view"
    "${CMAKE_CURRENT_SOURCE_DIR}/src/library"
)

target_link_libraries(jankk PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::Multimedia
    Ryu::Shapes
    Ryu::Shapesplugin
    Ryu::Extraa
    Ryu::Extraaplugin
    "${MGBA_LIBRARY}"
)

qt_import_qml_plugins(jankk)

qt_add_executable(headless_test src/headless_test.cpp)
target_include_directories(headless_test PRIVATE "${MGBA_INCLUDE_DIR}")
target_link_libraries(headless_test PRIVATE Qt6::Core Qt6::Gui "${MGBA_LIBRARY}")
target_compile_definitions(jankk PRIVATE JANKK_VERSION="${PROJECT_VERSION}")
