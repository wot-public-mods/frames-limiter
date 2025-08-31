# SPDX-License-Identifier: LGPL-3.0-or-later
# Copyright (c) 2021-2025 Mikhail Paulyshka

# project
cmake_minimum_required (VERSION 3.23)
project(frames_limiter)



#
# packages
#

find_package(pybind11 REQUIRED)
find_package(openwg_native_hooks REQUIRED)



#
# Library
#

function(add_owg_library vendor)
    find_package(libpython_${vendor} REQUIRED)

    add_library(frames_limiter_${vendor} SHARED)

    target_sources(frames_limiter_${vendor} PRIVATE
        "dllmain.cpp"
        "dllmain.h"
        "debug_logger.h"
        "frames_limiter.h"
        "frames_limiter.cpp"
        "python_module.cpp"
        "time_helper.h"
        "winapi_helper.h"
    )

    target_compile_definitions(frames_limiter_${vendor} PRIVATE "NOMINMAX")
    target_compile_definitions(frames_limiter_${vendor} PRIVATE "_USE_MATH_DEFINES")
    target_compile_definitions(frames_limiter_${vendor} PRIVATE "_CRT_SECURE_NO_WARNINGS")  

    target_link_libraries(frames_limiter_${vendor} PRIVATE libpython_${vendor}::libpython_${vendor})
    target_link_libraries(frames_limiter_${vendor} PRIVATE pybind11::pybind11)
    target_link_libraries(frames_limiter_${vendor} PRIVATE openwg_native_hooks::openwg_native_hooks)
    target_link_libraries(frames_limiter_${vendor} PRIVATE shlwapi Winmm ntdll)

    set_target_properties(frames_limiter_${vendor} PROPERTIES CXX_STANDARD 23)
    set_target_properties(frames_limiter_${vendor} PROPERTIES CXX_STANDARD_REQUIRED ON)
    set_target_properties(frames_limiter_${vendor} PROPERTIES COMPILE_FLAGS "/wd4005 /wd5033 /Zc:preprocessor")
    set_target_properties(frames_limiter_${vendor} PROPERTIES SUFFIX ".pyd")
    set_target_properties(frames_limiter_${vendor} PROPERTIES OUTPUT_NAME "frames_limiter")
    set_target_properties(frames_limiter_${vendor} PROPERTIES ARCHIVE_OUTPUT_DIRECTORY "${vendor}")
    set_target_properties(frames_limiter_${vendor} PROPERTIES LIBRARY_OUTPUT_DIRECTORY "${vendor}")
    set_target_properties(frames_limiter_${vendor} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${vendor}")

    install(
      TARGETS frames_limiter_${vendor}
      RUNTIME DESTINATION bin_${vendor}
    )
endfunction()

add_owg_library(lesta)
add_owg_library(wg)
