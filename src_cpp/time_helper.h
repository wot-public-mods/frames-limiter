// SPDX-License-Identifier: LGPL-3.0-or-later
// Copyright(c) 2021 Andrey Andruschyshyn. All rights reserved.
// Copyright(c) 2021 Mikhail Paulyshka. All rights reserved.

#pragma once

#include <chrono>

namespace frames_limiter {

	class TimeHelper {
	public:
		TimeHelper() = delete;
		~TimeHelper() = delete;

		static uint64_t get_time_ns()
		{
			return std::chrono::steady_clock::now().time_since_epoch().count();
		}
	};

}