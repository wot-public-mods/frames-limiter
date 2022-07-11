cmake_minimum_required (VERSION 3.0)

project(frames_limiter)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(libpython REQUIRED)
find_package(xfw_hooks REQUIRED)

add_library(frames_limiter SHARED )

target_sources(frames_limiter PRIVATE
    "dllmain.cpp"
    "dllmain.h"

    "debug_logger.h"

    "frames_limiter.h"
    "frames_limiter.cpp"

    "python_module.cpp"

    "time_helper.h"

    "winapi_helper.h"
)

target_compile_definitions(frames_limiter PRIVATE "-DNOMINMAX")
target_compile_definitions(frames_limiter PRIVATE "-D_USE_MATH_DEFINES")
target_compile_definitions(frames_limiter PRIVATE "-D_CRT_SECURE_NO_WARNINGS")

target_link_libraries(frames_limiter xfw_hooks::xfw_hooks)
target_link_libraries(frames_limiter libpython::python27)
target_link_libraries(frames_limiter shlwapi Winmm ntdll)

set_target_properties(frames_limiter PROPERTIES COMPILE_FLAGS "/wd4005 /wd5033")
set_target_properties(frames_limiter PROPERTIES SUFFIX ".pyd")

#
# Install
#

install(
    TARGETS frames_limiter
    RUNTIME DESTINATION bin
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
)
