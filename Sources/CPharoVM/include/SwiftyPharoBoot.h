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
/// pluginsPath is the directory holding libFilePlugin, libSocketPlugin and the
/// rest; the VM dlopens them by leaf name as the image asks for them.
SwiftyPharoState swifty_pharo_boot(const char *imagePath, const char *pluginsPath, int argc, const char **argv,
                                   const char **environment);

SwiftyPharoState swifty_pharo_state(void);

#endif
