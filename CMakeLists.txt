cmake_minimum_required(VERSION 3.21)
project(_jankk VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)
qt_standard_project_setup(REQUIRES 6.5)

set(RYU_MODULES "Shapes" CACHE STRING "" FORCE)
set(RYU_STATIC  ON       CACHE BOOL   "" FORCE)
set(RYU_INSTALL OFF      CACHE BOOL   "" FORCE)
add_subdirectory(third_party/ryu)

qt_add_executable(_jankk src/main.cpp)

qt_add_qml_module(_jankk
    URI Jankk
    VERSION 1.0
    QML_FILES qml/Main.qml
)

target_link_libraries(_jankk PRIVATE
    Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick
    Ryu::Shapes
    Ryu::Shapesplugin
)

qt_import_qml_plugins(_jankk)
