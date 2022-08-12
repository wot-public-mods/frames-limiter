// SPDX-License-Identifier: LGPL-3.0-or-later
// Copyright(c) 2021 Andrey Andruschyshyn. All rights reserved.
// Copyright(c) 2021 Mikhail Paulyshka. All rights reserved.

#include <functional>

#include "debug_logger.h"
#include "frames_limiter.h"
#include "time_helper.h"
#include "winapi_helper.h"

using namespace std::placeholders;

// used in the waiting loop sleep logic
// can be lower, close to 1`000`000 (1 ms)
#define DISABLE_SLEEP_TIME_LEFT 2'000'000
#define SLEEP_TIMEOUT_QUADNS 1'000


namespace frames_limiter {

	FramesLimiter::FramesLimiter() : _hooks_d3d(XFW::Native::Hooks::HookmanagerD3D::instance())
	{
		set_target_fps(0);

		// Interval arg for NtDelayExecution
		// NtDelayExecution expects time in 100ns quantas
		_sleep_interval.QuadPart = -(SLEEP_TIMEOUT_QUADNS / 100); 
	}

	FramesLimiter::~FramesLimiter()
	{
		dxgi_unhook();
	}

	bool FramesLimiter::set_hook_status(const bool enabled)
	{
		return enabled ? dxgi_hook() : dxgi_unhook();
	}

	bool FramesLimiter::set_target_fps(const int fps)
	{
		if (fps < 0) {
			return false;
		}

		if (fps == 0) {
			_target_fps = 0;
			_target_frametime = 0;
			return true;
		}

		_target_fps = fps;
		_target_frametime = 1'000'000'000 / _target_fps;
		return true;
	}

	bool FramesLimiter::dxgi_hook()
	{
		bool result = false;

		_hooks_d3d.init();
		if (_hooks_d3d.inited()) {
			_hooks_d3d.IDXGISwapChain_Present_register("poliroid_frames_limiter", XFW::Native::Hooks::HookPlace::Before,
				std::bind(&FramesLimiter::onPresent, this, _1, _2, _3));
			result = true;
		}
		
		timeBeginPeriod(1);

		return true;
	}

	bool FramesLimiter::dxgi_unhook()
	{
		bool result = false;

		if (_hooks_d3d.inited()) {
			_hooks_d3d.IDXGISwapChain_Present_unregister("poliroid_frames_limiter", XFW::Native::Hooks::HookPlace::Before);
			result = true;
		}

		timeEndPeriod(1);

		return result;
	}

	void FramesLimiter::onPresent(IDXGISwapChain* swapChain, UINT, UINT)
	{
		_last_frametick = _curr_frametick;
		_curr_frametick = TimeHelper::get_time_ns();

		if (!_target_frametime || !_last_frametick) {
			return;
		}

		//wait for long time using sleep
		while (_curr_frametick - _last_frametick < _target_frametime &&
			(_target_frametime - (_curr_frametick - _last_frametick) > DISABLE_SLEEP_TIME_LEFT)) {
			NtDelayExecution(FALSE, &_sleep_interval);
			_curr_frametick = TimeHelper::get_time_ns();
		}

		//wait for small time in a loop
		while (_curr_frametick - _last_frametick < _target_frametime) {
			YieldProcessor();
			_curr_frametick = TimeHelper::get_time_ns();
		}
	}

}