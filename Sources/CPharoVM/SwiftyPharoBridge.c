#include "include/SwiftyPharoBridge.h"

#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#include <windows.h>
#else
#include <pthread.h>
#include <time.h>
#endif

// Long enough for a slow image to finish starting, short enough that a host
// waiting on a bridge that will never arrive hears about it.
#define SWIFTY_PHARO_BRIDGE_TIMEOUT_SECONDS 30

typedef struct Message Message;

struct Message {
    Message *next;
    char *text;
};

extern intptr_t signalSemaphoreWithIndex(intptr_t index);

static int semaphoreIndex = 0;
static Message *oldestMessage = NULL;
static Message *newestMessage = NULL;
static SwiftyPharoReplyHandler replyHandler = NULL;

static void enqueueMessage(const char *text);
static Message *dequeueMessage(void);
static void lockMailbox(void);
static void unlockMailbox(void);
static void announceBridge(void);
static void awaitBridge(void);

void
swifty_pharo_bridge_ready(int index)
{
    lockMailbox();
    semaphoreIndex = index;
    announceBridge();
    unlockMailbox();
}

bool
swifty_pharo_bridge_is_ready(void)
{
    return __atomic_load_n(&semaphoreIndex, __ATOMIC_SEQ_CST) != 0;
}

void
swifty_pharo_receive_replies(SwiftyPharoReplyHandler handler)
{
    replyHandler = handler;
}

int
swifty_pharo_post(const char *message)
{
    int index;

    lockMailbox();
    awaitBridge();
    index = semaphoreIndex;
    if (index != 0)
        enqueueMessage(message);
    unlockMailbox();

    if (index == 0)
        return SWIFTY_PHARO_BRIDGE_UNAVAILABLE;

    signalSemaphoreWithIndex(index);

    return 0;
}

char *
swifty_pharo_next_message(void)
{
    Message *message;
    char *text;

    lockMailbox();
    message = dequeueMessage();
    unlockMailbox();

    if (message == NULL)
        return NULL;

    text = message->text;
    free(message);

    return text;
}

void
swifty_pharo_reply(int64_t request, const char *reply)
{
    replyHandler(request, reply);
}

void
swifty_pharo_interrupted(int64_t request)
{
    replyHandler(request, NULL);
}

static void
enqueueMessage(const char *text)
{
    size_t size = strlen(text) + 1;
    Message *message = malloc(sizeof(Message));

    message->next = NULL;
    message->text = malloc(size);
    memcpy(message->text, text, size);

    if (newestMessage == NULL)
        oldestMessage = message;
    else
        newestMessage->next = message;
    newestMessage = message;
}

static Message *
dequeueMessage(void)
{
    Message *message = oldestMessage;

    if (message == NULL)
        return NULL;

    oldestMessage = message->next;
    if (oldestMessage == NULL)
        newestMessage = NULL;

    return message;
}

#ifdef _WIN32

static SRWLOCK mailboxMutex = SRWLOCK_INIT;
static CONDITION_VARIABLE bridgeArrived = CONDITION_VARIABLE_INIT;

static void
lockMailbox(void)
{
    AcquireSRWLockExclusive(&mailboxMutex);
}

static void
unlockMailbox(void)
{
    ReleaseSRWLockExclusive(&mailboxMutex);
}

static void
announceBridge(void)
{
    WakeAllConditionVariable(&bridgeArrived);
}

static void
awaitBridge(void)
{
    ULONGLONG deadline = GetTickCount64() + SWIFTY_PHARO_BRIDGE_TIMEOUT_SECONDS * 1000ULL;

    while (semaphoreIndex == 0) {
        ULONGLONG now = GetTickCount64();
        if (now >= deadline)
            break;
        if (!SleepConditionVariableSRW(&bridgeArrived, &mailboxMutex, (DWORD)(deadline - now), 0))
            break;
    }
}

#else

static pthread_mutex_t mailboxMutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t bridgeArrived = PTHREAD_COND_INITIALIZER;

static void
lockMailbox(void)
{
    pthread_mutex_lock(&mailboxMutex);
}

static void
unlockMailbox(void)
{
    pthread_mutex_unlock(&mailboxMutex);
}

static void
announceBridge(void)
{
    pthread_cond_broadcast(&bridgeArrived);
}

static void
awaitBridge(void)
{
    struct timespec deadline;

    // C11 rather than POSIX: the wall clock pthread_cond_timedwait wants, named
    // the one way every platform this builds on has it.
    timespec_get(&deadline, TIME_UTC);
    deadline.tv_sec += SWIFTY_PHARO_BRIDGE_TIMEOUT_SECONDS;

    while (semaphoreIndex == 0) {
        if (pthread_cond_timedwait(&bridgeArrived, &mailboxMutex, &deadline) != 0)
            break;
    }
}

#endif
