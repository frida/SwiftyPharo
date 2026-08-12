#ifndef SWIFTY_PHARO_BRIDGE_H
#define SWIFTY_PHARO_BRIDGE_H

#include <stdbool.h>

#ifdef _WIN32
#   define SWIFTY_PHARO_RESOLVED_BY_NAME __declspec(dllexport)
#else
#   define SWIFTY_PHARO_RESOLVED_BY_NAME
#endif

/// Called by the image once its request thunk exists.
SWIFTY_PHARO_RESOLVED_BY_NAME void swifty_pharo_thunk_ready(void *thunk);

#define SWIFTY_PHARO_BRIDGE_UNAVAILABLE (-1)

bool swifty_pharo_bridge_is_ready(void);

/// Runs one request in the image and returns the reply's length, which exceeds
/// capacity when the reply did not fit, or SWIFTY_PHARO_BRIDGE_UNAVAILABLE when
/// the image never offered one. Blocks, so keep it off the main thread.
int swifty_pharo_request(const char *request, char *response, int capacity);

#endif
