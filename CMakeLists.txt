cmake_minimum_required(VERSION 3.21)
project(_jankk VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)
qt_standard_project_setup(REQUIRES 6.5)

qt_add_executable(_jankk src/main.cpp)

qt_add_qml_module(_jankk
    URI Jankk
    VERSION 1.0
    QML_FILES qml/Main.qml
)

target_link_libraries(_jankk PRIVATE Qt6::Quick)
