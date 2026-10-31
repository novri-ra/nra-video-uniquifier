cmake_minimum_required(VERSION 3.10.2)
project(ncnn_sr LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(ncnn_sr SHARED
    ncnn_sr_jni.cpp
)

find_library(log-lib log)

target_link_libraries(ncnn_sr
    ${log-lib}
)
