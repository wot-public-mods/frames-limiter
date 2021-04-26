// SPDX-License-Identifier: LGPL-3.0-or-later
// Copyright(c) 2021 Andrey Andruschyshyn. All rights reserved.
// Copyright(c) 2021 Mikhail Paulyshka. All rights reserved.

#pragma once

//stdlib
#include <string>
#include <sstream>

//Windows
#include <windows.h>

namespace frames_limiter
{

    class debug_logger
    {
    public:
        debug_logger() = delete;
        ~debug_logger() = delete;

        template<class... Args>
        static void log(Args... args)
        {
            std::stringstream ss;
            (ss << ... << args) << "\n";

            auto str = ss.str();
            OutputDebugStringA(str.c_str());
        }
    };

}