#include "include/SwiftyPharoBridge.h"

#include <pthread.h>
#include <time.h>

// Long enough for a slow image to finish starting, short enough that a host
// waiting on a bridge that will never arrive hears about it.
#define SWIFTY_PHARO_BRIDGE_TIMEOUT_SECONDS 30

typedef int (*RequestThunk)(const char *request, char *response, int capacity);

static RequestThunk requestThunk = NULL;
static pthread_mutex_t thunkMutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t thunkArrived = PTHREAD_COND_INITIALIZER;

void
swifty_pharo_thunk_ready(void *thunk)
{
    pthread_mutex_lock(&thunkMutex);
    requestThunk = (RequestThunk)thunk;
    pthread_cond_broadcast(&thunkArrived);
    pthread_mutex_unlock(&thunkMutex);
}

bool
swifty_pharo_bridge_is_ready(void)
{
    return __atomic_load_n(&requestThunk, __ATOMIC_SEQ_CST) != NULL;
}

int
swifty_pharo_request(const char *request, char *response, int capacity)
{
    RequestThunk thunk;
    struct timespec deadline;

    clock_gettime(CLOCK_REALTIME, &deadline);
    deadline.tv_sec += SWIFTY_PHARO_BRIDGE_TIMEOUT_SECONDS;

    pthread_mutex_lock(&thunkMutex);
    while (requestThunk == NULL) {
        if (pthread_cond_timedwait(&thunkArrived, &thunkMutex, &deadline) != 0)
            break;
    }
    thunk = requestThunk;
    pthread_mutex_unlock(&thunkMutex);

    if (thunk == NULL)
        return SWIFTY_PHARO_BRIDGE_UNAVAILABLE;

    return thunk(request, response, capacity);
}
