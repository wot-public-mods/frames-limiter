// SPDX-License-Identifier: LGPL-3.0-or-later
// Copyright(c) 2021 Andrey Andruschyshyn. All rights reserved.
// Copyright(c) 2021 Mikhail Paulyshka. All rights reserved.

#pragma once

#include <cstdint>

class MemoryHelper {
public:

	MemoryHelper() = delete;
	~MemoryHelper() = delete;

	static uint32_t get_32bit(size_t address);
	static uint64_t get_64bit(size_t address);
};