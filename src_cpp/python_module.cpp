// SPDX-License-Identifier: LGPL-3.0-or-later
// Copyright(c) 2021 Andrey Andruschyshyn. All rights reserved.
// Copyright(c) 2021 Mikhail Paulyshka. All rights reserved.

#include "frames_limiter.h"
#include <pybind11/pybind11.h>

namespace frames_limiter {

	PYBIND11_MODULE(Frames_Limiter, m) {

		m.doc() = "Frames limiter module";

		pybind11::class_<FramesLimiter>(m, "Frames_Limiter_Instance")
			.def(pybind11::init<>())
			.def("set_hook_status", &FramesLimiter::set_hook_status, "Set Frames Limiter status")
			.def("set_target_fps", &FramesLimiter::set_target_fps, "Set Frame Limiter target FPS")
		;
	}
}