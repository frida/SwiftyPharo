#ifndef SWIFTY_PHARO_BRIDGE_H
#define SWIFTY_PHARO_BRIDGE_H

#include <stdbool.h>

/// Called by the image once its request thunk exists.
void swifty_pharo_thunk_ready(void *thunk);

bool swifty_pharo_bridge_is_ready(void);

/// Runs one request in the image and returns the reply's length, which exceeds
/// capacity when the reply did not fit. Blocks, so keep it off the main thread.
int swifty_pharo_request(const char *request, char *response, int capacity);

#endif
