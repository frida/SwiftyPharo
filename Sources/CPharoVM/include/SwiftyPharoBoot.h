#ifndef SWIFTY_PHARO_BOOT_H
#define SWIFTY_PHARO_BOOT_H

typedef enum {
    SwiftyPharoStateStarting = 0,
    SwiftyPharoStateRunning,
    SwiftyPharoStateImageLoadFailed,
    SwiftyPharoStateThreadSpawnFailed,
} SwiftyPharoState;

/// Boots the Pharo VM on a dedicated thread and returns immediately, leaving the
/// calling thread free to keep driving its UI toolkit. Progress is observed
/// through swifty_pharo_state().
///
/// The plugins the VM loads as the image asks for them are found beside
/// libPharoVMCore, so ship the two in one directory.
SwiftyPharoState swifty_pharo_boot(const char *imagePath, int argc, const char **argv, const char **environment);

SwiftyPharoState swifty_pharo_state(void);

#endif
