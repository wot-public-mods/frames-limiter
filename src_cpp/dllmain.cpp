// SPDX-License-Identifier: LGPL-3.0-or-later
// Copyright(c) 2021 Andrey Andruschyshyn. All rights reserved.
// Copyright(c) 2021 Mikhail Paulyshka. All rights reserved.
#include "dllmain.h"

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD     fdwReason, LPVOID    lpvReserved)
{
	switch (fdwReason)
	{
	case DLL_PROCESS_ATTACH:
		DisableThreadLibraryCalls(hinstDLL);
		break;

	case DLL_PROCESS_DETACH:
		break;

	default:
		break;
	}

	return TRUE;
}