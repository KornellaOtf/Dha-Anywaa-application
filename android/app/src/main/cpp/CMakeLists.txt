cmake_minimum_required(VERSION 3.22.1)
project(keyguard C)

add_library(keyguard SHARED key_guard.c)
find_library(log-lib log)
target_link_libraries(keyguard ${log-lib} android)
target_link_options(keyguard PRIVATE -s)
