#include "include/SwiftyPharoBridge.h"

#ifdef _WIN32
#include <windows.h>
#else
#include <pthread.h>
#include <time.h>
#endif

// Long enough for a slow image to finish starting, short enough that a host
// waiting on a bridge that will never arrive hears about it.
#define SWIFTY_PHARO_BRIDGE_TIMEOUT_SECONDS 30

typedef int (*RequestThunk)(const char *request, char *response, int capacity);

static RequestThunk requestThunk = NULL;

static void lockThunk(void);
static void unlockThunk(void);
static void announceThunk(void);
static void awaitThunk(void);

void
swifty_pharo_thunk_ready(void *thunk)
{
    lockThunk();
    requestThunk = (RequestThunk)thunk;
    announceThunk();
    unlockThunk();
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

    lockThunk();
    awaitThunk();
    thunk = requestThunk;
    unlockThunk();

    if (thunk == NULL)
        return SWIFTY_PHARO_BRIDGE_UNAVAILABLE;

    return thunk(request, response, capacity);
}

#ifdef _WIN32

static SRWLOCK thunkMutex = SRWLOCK_INIT;
static CONDITION_VARIABLE thunkArrived = CONDITION_VARIABLE_INIT;

static void
lockThunk(void)
{
    AcquireSRWLockExclusive(&thunkMutex);
}

static void
unlockThunk(void)
{
    ReleaseSRWLockExclusive(&thunkMutex);
}

static void
announceThunk(void)
{
    WakeAllConditionVariable(&thunkArrived);
}

static void
awaitThunk(void)
{
    ULONGLONG deadline = GetTickCount64() + SWIFTY_PHARO_BRIDGE_TIMEOUT_SECONDS * 1000ULL;

    while (requestThunk == NULL) {
        ULONGLONG now = GetTickCount64();
        if (now >= deadline)
            break;
        if (!SleepConditionVariableSRW(&thunkArrived, &thunkMutex, (DWORD)(deadline - now), 0))
            break;
    }
}

#else

static pthread_mutex_t thunkMutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t thunkArrived = PTHREAD_COND_INITIALIZER;

static void
lockThunk(void)
{
    pthread_mutex_lock(&thunkMutex);
}

static void
unlockThunk(void)
{
    pthread_mutex_unlock(&thunkMutex);
}

static void
announceThunk(void)
{
    pthread_cond_broadcast(&thunkArrived);
}

static void
awaitThunk(void)
{
    struct timespec deadline;

    // C11 rather than POSIX: the wall clock pthread_cond_timedwait wants, named
    // the one way every platform this builds on has it.
    timespec_get(&deadline, TIME_UTC);
    deadline.tv_sec += SWIFTY_PHARO_BRIDGE_TIMEOUT_SECONDS;

    while (requestThunk == NULL) {
        if (pthread_cond_timedwait(&thunkArrived, &thunkMutex, &deadline) != 0)
            break;
    }
}

#endif
