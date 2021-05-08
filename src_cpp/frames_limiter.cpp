// SPDX-License-Identifier: LGPL-3.0-or-later
// Copyright(c) 2021 Andrey Andruschyshyn. All rights reserved.
// Copyright(c) 2021 Mikhail Paulyshka. All rights reserved.

#include "debug_logger.h"
#include "frames_limiter.h"
#include "memory_helper.h"

#include "time_helper.h"
#include "winapi_helper.h"

#define DXGISWAPCHAIN_PRESENT_INDEX 8

// used in the waiting loop sleep logic
// can be lower, close to 1`000`000 (1 ms)
#define DISABLE_SLEEP_TIME_LEFT 2'000'000
#define SLEEP_TIMEOUT_QUADNS 1'000


namespace frames_limiter {

	FramesLimiter* FramesLimiter::_instance = nullptr;

	DXGI_SwapChain_Present_typedef FramesLimiter::dxgi_swapchain_present_o = nullptr;

	FramesLimiter::FramesLimiter()
	{
		_instance = this;
		MH_Initialize();
		kiero::init(kiero::RenderType::D3D11);
		set_target_fps(0);

		// Interval arg for NtDelayExecution
		// NtDelayExecution expects time in 100ns quantas
		_sleep_interval.QuadPart = -(SLEEP_TIMEOUT_QUADNS / 100); 
	}

	FramesLimiter::~FramesLimiter()
	{
		dxgi_unhook();
		kiero::shutdown();

		_instance = nullptr;
	}

	FramesLimiter* FramesLimiter::Instance()
	{
		return _instance;
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

	void* FramesLimiter::get_hook_target()
	{
		uint8_t* _target = (uint8_t*)kiero::getMethodsTable()[DXGISWAPCHAIN_PRESENT_INDEX];
		uint8_t* _target_final = nullptr;

		//whoops, we are hooked
		if (_target[0] == 0xE9) {
			_target_final = _target + 1 + MemoryHelper::get_32bit(reinterpret_cast<size_t>(_target + 1)) + 4;

#if defined(_WIN64)
			_target_final -= 0x100000000;
#endif
		}
		
		if (_target_final) {
			_target = _target_final;
		}

		return reinterpret_cast<void*>(_target);
	}

	bool FramesLimiter::dxgi_hook()
	{
		if (_dx_hooked_address)
		{
			return false;
		}

		void* target = get_hook_target();

		if (MH_CreateHook(target, &FramesLimiter::CallBack_DxgiPresent, reinterpret_cast<void**>(&dxgi_swapchain_present_o)) != MH_OK) {
			return false;
		}
		
		if(MH_EnableHook(target) != MH_OK)
		{
			return false;
		}

		timeBeginPeriod(1);
		_dx_hooked_address = target;
		return true;
	}

	bool FramesLimiter::dxgi_unhook()
	{
		if (!_dx_hooked_address)
		{
			return false;
		}

		timeEndPeriod(1);

		bool result = MH_DisableHook(_dx_hooked_address) == MH_OK && MH_RemoveHook(_dx_hooked_address) == MH_OK;
		
		_dx_hooked_address = nullptr;
		
		return result;
	}

	HRESULT __stdcall FramesLimiter::CallBack_DxgiPresent(IDXGISwapChain* pSwapChain, UINT SyncInterval, UINT Flags)
	{
		auto* limiter = FramesLimiter::Instance();
		if (limiter) {
			limiter->frameTick();
		}
		return dxgi_swapchain_present_o(pSwapChain, SyncInterval, Flags);
	}

	void FramesLimiter::frameTick()
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