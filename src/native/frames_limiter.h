// SPDX-License-Identifier: LGPL-3.0-or-later
// Copyright(c) 2021 Andrey Andruschyshyn. All rights reserved.
// Copyright(c) 2021 Mikhail Paulyshka. All rights reserved.

#pragma once

#include <xfw_native_hooks_d3d.h>

namespace frames_limiter {
	
	typedef HRESULT(__stdcall* DXGI_SwapChain_Present_typedef)(IDXGISwapChain* pSwapChain, UINT SyncInterval, UINT Flags);

	class FramesLimiter {
	public:
		FramesLimiter();
		~FramesLimiter();

		static FramesLimiter* Instance();

		bool set_target_fps(const int fps);

		bool set_hook_status(const bool enabled);

	private:
		bool dxgi_hook();
		bool dxgi_unhook();
		void frameTick();

		void onPresent(IDXGISwapChain* swapChain, UINT, UINT);
	
	private:
		uint64_t _target_fps = 0;
		uint64_t _target_frametime = 0;

		uint64_t _curr_frametick = 0;
		uint64_t _last_frametick = 0;

		LARGE_INTEGER _sleep_interval{};

		XFW::Native::Hooks::HookmanagerD3D& _hooks_d3d;


	};

}