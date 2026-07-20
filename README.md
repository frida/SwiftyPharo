# SwiftyPharo

Swift bindings for embedding the [Pharo](https://pharo.org) VM in a native
application.

The VM runs on a thread of its own, so the host keeps its main thread for its UI
toolkit. It is embedded in-process — there is no helper process, no socket, and
no port.

```swift
import SwiftyPharo

PharoRuntime.shared.boot(image: imageURL)
try await PharoRuntime.shared.runningState()
```

## Laying out the runtime

**Unpack `PharoVMPlugins-<platform>.zip` into the directory holding
`libPharoVMCore`.** The plugins behind the file, socket and SSL primitives are
loaded from wherever the core sits, so an image that cannot find them starts,
spins and never answers. SwiftPM copies the core next to the product, and the
stock `Pharo.app` keeps the two together in `Contents/MacOS/Plugins` for the
same reason; Windows resolves DLLs from the loading module's directory, so one
directory suits every platform.

There is a `pluginPaths` global in the VM that looks like the place to point at
a plugins directory. It is not: the image loads its plugins just as happily with
that global aimed at a directory that does not exist.

## How it embeds

`libPharoVMCore` exposes four entry points. SwiftyPharo drives `vm_init` and
`vm_run_interpreter` directly rather than calling `vm_main_with_parameters`,
because that would call `installErrorHandlers()` and replace the host's
SIGSEGV/SIGBUS handlers. A host that already handles crashes — or that runs
alongside Frida — needs to keep its own.

Two further details the upstream launcher takes care of, and an embedder must:

- `vm_init` records `ioVMThread` from the calling thread, so it runs on the
  interpreter thread rather than the one that asked for the boot.
- `osCogStackPageHeadroom()` caches the machine-code zone offset; the JIT
  computes wrong code addresses without it.

Upstream's worker mode ends in `runMainThreadWorker()`, which never returns.
SwiftyPharo instead spawns that worker on its own thread, so main-queue FFI is
still serviced while the caller's thread stays free.

## Calling across the boundary

Both directions are plain FFI.

Pharo reaches functions exported by the host executable — link the host with
`-Wl,-export_dynamic`:

```smalltalk
addr := ExternalAddress loadSymbol: 'luma_ping' module: nil.
defn := TFFunctionDefinition
    parameterTypes: { TFBasicType sint32 }
    returnType: TFBasicType sint32.
fn := TFExternalFunction fromAddress: addr definition: defn.
TFSameThreadRunner uniqueInstance invokeFunction: fn withArguments: #(21)
```

The host calls into the image through a callback thunk. The runner **must** be
bound when the callback is created:

```smalltalk
worker := TFWorker named: 'host'.
worker ensureInitialized.
cb := TFCallback
    forCallback: [ :v | v * 3 ]
    parameters: { TFBasicType sint32 }
    returnType: TFBasicType sint32
    runner: worker.
```

Creating the callback with `FFICallback signature:block:` and assigning
`backendCallback runner:` afterwards compiles and works when invoked from inside
the image, but silently hangs any call arriving on a foreign thread. Retain the
callback too — the callback queue holds it weakly, and a collected closure
crashes later calls.

## Building the VM

Building happens in two steps, so slices from several machines can be combined:
`build-vm.sh` builds the VM for the host architecture and stages one slice plus
`PharoVMPlugins-<platform>.zip`, and `make-xcframework.sh` folds the staged
slices into `PharoVM.xcframework` and prints its checksum. Dropping SDL2, Cairo,
FreeType and libgit2 takes the VM from ~34 MB to ~3 MB; a headless embedding uses
none of them.

```sh
PLATFORM=macos        tools/build-vm.sh
PLATFORM=ios          tools/build-vm.sh
PLATFORM=iossimulator tools/build-vm.sh
tools/make-xcframework.sh
```

macOS gets the Cog JIT; iOS gets the plain interpreter, since the JIT wants
writable-executable memory that iOS withholds. pharo-vm has no iOS platform file
and links AppKit for its image-picker dialog, so `tools/pharo-vm-ios/iOS.cmake`
supplies one and swaps in the Unix no-op dialog. libffi comes from
[frida/libffi](https://github.com/frida/libffi): the iPhoneOS SDK ships none,
and pharo's own copy does not cross-compile.

macOS builds arm64 and x86_64 in one pass, so the slice is already universal.
The `VM` workflow builds all three on CI, and pushing a `vm-*` tag publishes the
xcframework and the plugin archive to this repo's releases. Paste the printed
checksum into `Package.swift`.

`PharoVM.xcframework` covers the Apple platforms. Elsewhere the package links a
system-installed VM, discovered through `pkg-config` on Linux; point
`PHARO_VM_ROOT` at a local build to override either.

## Images

The image needs UnifiedFFI, and the minimal Pharo image does not ship it —
`FFIBackend current` answers `a NullFFIBackend` there, while a full image answers
`a TFFIBackend`. Load UnifiedFFI into whatever image you bundle.

## License

MIT
