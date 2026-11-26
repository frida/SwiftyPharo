#ifndef SWIFTY_PHARO_BRIDGE_H
#define SWIFTY_PHARO_BRIDGE_H

#include <stdbool.h>
#include <stdint.h>

#ifdef _WIN32
#   define SWIFTY_PHARO_RESOLVED_BY_NAME __declspec(dllexport)
#else
#   define SWIFTY_PHARO_RESOLVED_BY_NAME
#endif

/// Called by the image once it is ready for requests.
SWIFTY_PHARO_RESOLVED_BY_NAME void swifty_pharo_bridge_ready(int semaphoreIndex);

SWIFTY_PHARO_RESOLVED_BY_NAME char *swifty_pharo_next_message(void);

SWIFTY_PHARO_RESOLVED_BY_NAME void swifty_pharo_reply(int64_t request, const char *reply);

SWIFTY_PHARO_RESOLVED_BY_NAME void swifty_pharo_interrupted(int64_t request);

#define SWIFTY_PHARO_BRIDGE_UNAVAILABLE (-1)

typedef void (*SwiftyPharoReplyHandler)(int64_t request, const char *reply);

bool swifty_pharo_bridge_is_ready(void);

void swifty_pharo_receive_replies(SwiftyPharoReplyHandler handler);

/// Hands one message to the image and returns 0, or
/// SWIFTY_PHARO_BRIDGE_UNAVAILABLE when the image never offered a bridge.
/// Blocks, so keep it off the main thread.
int swifty_pharo_post(const char *message);

#endif
