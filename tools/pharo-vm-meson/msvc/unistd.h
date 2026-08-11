/* Upstream guards this header everywhere but parameters.c, which MinGW lets
 * pass because it ships one. MSVC does not, and what that file wants from it
 * is chdir. */
#pragma once

#include <direct.h>
#include <io.h>
#include <process.h>

#define chdir _chdir
