/* MinGW ships winpthreads, and upstream's Windows build leans on it for the
 * four calls the FFI worker makes. A thread here is its id: that is what
 * upstream types sqOSThread as, and identity is all the worker compares.
 */
#pragma once

#include <errno.h>
#include <stdlib.h>
#include <windows.h>

typedef DWORD pthread_t;
typedef void pthread_attr_t;

typedef struct {
    void *(*start)(void *);
    void *argument;
} SwiftyPharoThreadStart;

static DWORD WINAPI
swifty_pharo_thread_main(LPVOID parameter)
{
    SwiftyPharoThreadStart start = *(SwiftyPharoThreadStart *)parameter;

    free(parameter);
    start.start(start.argument);

    return 0;
}

static inline int
pthread_create(pthread_t *thread, const pthread_attr_t *attributes,
               void *(*start)(void *), void *argument)
{
    SwiftyPharoThreadStart *carried;
    HANDLE handle;

    carried = malloc(sizeof(*carried));
    carried->start = start;
    carried->argument = argument;

    handle = CreateThread(NULL, 0, swifty_pharo_thread_main, carried, 0, thread);
    if (handle == NULL) {
        free(carried);
        return EAGAIN;
    }

    // Nothing ever joins these, so the handle goes now and detach has nothing
    // left to do.
    CloseHandle(handle);

    return 0;
}

static inline int
pthread_detach(pthread_t thread)
{
    return 0;
}

static inline pthread_t
pthread_self(void)
{
    return GetCurrentThreadId();
}

static inline int
pthread_equal(pthread_t one, pthread_t other)
{
    return one == other;
}
