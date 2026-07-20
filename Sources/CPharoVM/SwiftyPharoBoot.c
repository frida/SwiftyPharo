#include "include/SwiftyPharoBoot.h"

#include <stdbool.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#include <process.h>
#include <windows.h>
#else
#include <pthread.h>
#endif

#include <PharoVM/pharoClient.h>

extern int vmRunOnWorkerThread;
extern void setProcessArguments(int argc, const char **argv);
extern void setProcessEnvironmentVector(const char **environment);
extern void registerCurrentThreadToHandleExceptions(void);

typedef struct Worker Worker;
extern Worker *worker_newSpawning(int spawn);
extern Worker *mainThreadWorker;

static VMParameters *newInterpreterParameters(const char *imagePath, int argc, const char **argv,
                                              const char **environment);
static void configureProcessContext(int argc, const char **argv, const char **environment);
static void spawnMainQueueFFIWorker(void);
static int spawnInterpreterThread(VMParameters *parameters);
static void runInterpreter(VMParameters *parameters);

static SwiftyPharoState currentState = SwiftyPharoStateStarting;
static bool booted = false;

// vm_main_with_parameters() would install its own SIGSEGV/SIGBUS handlers.
SwiftyPharoState
swifty_pharo_boot(const char *imagePath, int argc, const char **argv, const char **environment)
{
    // The VM keeps its state in globals, so a second vm_init() would run over
    // the interpreter already using them and leave it jumping through null.
    if (booted)
        return currentState;
    booted = true;

    VMParameters *parameters = newInterpreterParameters(imagePath, argc, argv, environment);

    configureProcessContext(argc, argv, environment);
    osCogStackPageHeadroom();
    spawnMainQueueFFIWorker();

    if (spawnInterpreterThread(parameters) != 0)
        currentState = SwiftyPharoStateThreadSpawnFailed;

    return currentState;
}

SwiftyPharoState
swifty_pharo_state(void)
{
    return currentState;
}

// Runs once the image has finished starting, where the callback runner is
// dependable; building the thunk from a startup handler is not. The script
// never returns, so the image stays up serving requests.
static const char *bridgeStartup[] = {
    "eval",
    "SwpBridge install. [ (Delay forSeconds: 3600) wait ] repeat",
};

// Heap-allocated because the interpreter thread outlives swifty_pharo_boot().
static VMParameters *
newInterpreterParameters(const char *imagePath, int argc, const char **argv, const char **environment)
{
    VMParameters *parameters = calloc(1, sizeof(VMParameters));

    vm_parameters_init(parameters);
    vm_parameter_vector_insert_from(&parameters->imageParameters, 2, bridgeStartup);
    parameters->imageFileName = strdup(imagePath);
    parameters->isDefaultImage = false;
    parameters->defaultImageFound = true;
    parameters->isInteractiveSession = false;
    parameters->isWorker = true;
    parameters->processArgc = argc;
    parameters->processArgv = argv;
    parameters->environmentVector = environment;

    return parameters;
}

static void
configureProcessContext(int argc, const char **argv, const char **environment)
{
    vmRunOnWorkerThread = 1;
    setProcessArguments(argc, argv);
    setProcessEnvironmentVector(environment);
}

// runMainThreadWorker() never returns; spawning leaves the caller its thread.
static void
spawnMainQueueFFIWorker(void)
{
    mainThreadWorker = worker_newSpawning(1);
}

// The interpreter recurses far deeper than a default thread stack allows.
#define INTERPRETER_STACK_SIZE (4 * 1024 * 1024)

#ifdef _WIN32

static unsigned __stdcall interpreterThreadMain(void *context);

static int
spawnInterpreterThread(VMParameters *parameters)
{
    uintptr_t thread = _beginthreadex(NULL, INTERPRETER_STACK_SIZE, interpreterThreadMain, parameters, 0, NULL);
    if (thread == 0)
        return -1;

    CloseHandle((HANDLE)thread);

    return 0;
}

static unsigned __stdcall
interpreterThreadMain(void *context)
{
    runInterpreter(context);

    return 0;
}

#else

static void *interpreterThreadMain(void *context);

static int
spawnInterpreterThread(VMParameters *parameters)
{
    pthread_attr_t attributes;
    pthread_attr_init(&attributes);
    pthread_attr_setstacksize(&attributes, INTERPRETER_STACK_SIZE);
#ifdef __APPLE__
    // Callers block on this thread to get their answer, so leaving it at the
    // default class inverts their priority.
    pthread_attr_set_qos_class_np(&attributes, QOS_CLASS_USER_INITIATED, 0);
#endif

    pthread_t interpreterThread;
    int result = pthread_create(&interpreterThread, &attributes, interpreterThreadMain, parameters);
    if (result == 0)
        pthread_detach(interpreterThread);

    return result;
}

static void *
interpreterThreadMain(void *context)
{
    runInterpreter(context);

    return NULL;
}

#endif

// vm_init() records ioVMThread from the calling thread.
static void
runInterpreter(VMParameters *parameters)
{
    if (!vm_init(parameters)) {
        currentState = SwiftyPharoStateImageLoadFailed;
        return;
    }

    registerCurrentThreadToHandleExceptions();
    currentState = SwiftyPharoStateRunning;

    vm_run_interpreter();
}
