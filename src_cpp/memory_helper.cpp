// SPDX-License-Identifier: LGPL-3.0-or-later
// Copyright(c) 2021 Andrey Andruschyshyn. All rights reserved.
// Copyright(c) 2021 Mikhail Paulyshka. All rights reserved.

#include "memory_helper.h"

#include <Windows.h>

uint32_t MemoryHelper::get_32bit(size_t address)
{
	return *reinterpret_cast<uint32_t*>(address);
}

uint64_t MemoryHelper::get_64bit(size_t address)
{
	return *reinterpret_cast<uint64_t*>(address);
}


