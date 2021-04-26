// SPDX-License-Identifier: LGPL-3.0-or-later
// Copyright(c) 2021 Andrey Andruschyshyn. All rights reserved.
// Copyright(c) 2021 Mikhail Paulyshka. All rights reserved.

#pragma once

#include <Windows.h>

extern "C"
NTSYSAPI
NTSTATUS
NTAPI
NtDelayExecution(
	IN BOOLEAN              Alertable,
	IN PLARGE_INTEGER       Interval);
