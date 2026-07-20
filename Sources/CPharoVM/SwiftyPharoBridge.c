#include "include/SwiftyPharoBridge.h"

#include <pthread.h>

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

    pthread_mutex_lock(&thunkMutex);
    while (requestThunk == NULL)
        pthread_cond_wait(&thunkArrived, &thunkMutex);
    thunk = requestThunk;
    pthread_mutex_unlock(&thunkMutex);

    return thunk(request, response, capacity);
}
