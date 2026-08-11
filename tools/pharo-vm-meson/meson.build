project('pharo-vm', 'c',
  meson_version: '>=1.1',
  version: '12.0.0',
  default_options: [
    'c_std=gnu11',
    'warning_level=0',
    'buildtype=release',
    # Upstream builds at -O2, and an interpreter is a poor place to differ.
    'optimization=2',
  ],
)

# Slang runs a Pharo image to write the interpreter and the plugin primitives,
# which no build system can do for itself; upstream's CMake makes them and this
# build takes them as given.
# Relative to this file: Meson refuses an absolute path into the source tree.
generated = get_option('generated_dir')
generated_abs = meson.current_source_dir() / generated
flavour = get_option('flavour')
# A cross file says 'darwin' for both, and the two want different sources and
# different frameworks.
is_ios = get_option('ios')

cc = meson.get_compiler('c')
fs = import('fs')
pkg = import('pkgconfig')

host_os = host_machine.system()
is_darwin = host_os == 'darwin'
is_windows = host_os == 'windows'
platform_dir = 'unix'
if is_darwin
  platform_dir = 'osx'
elif is_windows
  platform_dir = 'win'
endif

# The endianness the VM was always given as a compile definition, which is what
# left it out of the installed headers and stopped every consumer of them.
lsb_first = host_machine.endian() == 'little' ? 1 : 0

conf = configuration_data()
# The template writes the quotes itself, so these go in bare.
conf.set('VM_NAME', 'Pharo')
conf.set('DEFAULT_IMAGE_NAME', 'Pharo.image')
conf.set('OS_TYPE', is_windows ? 'Win32' : 'unix')
conf.set('VM_TARGET', host_os)
conf.set('VM_TARGET_CPU', host_machine.cpu_family())
conf.set('VM_TARGET_OS', host_os)
conf.set('BUILT_FROM', 'SwiftyPharo')
conf.set('LSB_FIRST', lsb_first)
conf.set('ALWAYS_INTERACTIVE', 0)
conf.set('PharoVM_VERSION_MAJOR', 12)
conf.set('PharoVM_VERSION_MINOR', 0)
conf.set('PharoVM_VERSION_PATCH', 0)
conf.set('PharoVM_VERSION_STRING', '12.0.0')
conf.set('PHARO_VM_IN_WORKER_THREAD', 1)

foreach header : ['dirent.h', 'features.h', 'unistd.h', 'ndir.h', 'sys/ndir.h',
                  'sys/dir.h', 'sys/filio.h', 'sys/time.h', 'execinfo.h',
                  'dlfcn.h', 'sys/uuid.h', 'uuid/uuid.h', 'uuid.h']
  name = 'HAVE_' + header.to_upper().underscorify()
  conf.set(name, cc.has_header(header) ? 1 : false)
endforeach

foreach function : ['bzero', 'getcontext']
  conf.set('HAVE_' + function.to_upper(), cc.has_function(function) ? 1 : false)
endforeach

conf.set('HAVE_TM_GMTOFF',
  cc.has_member('struct tm', 'tm_gmtoff', prefix: '#include <time.h>') ? 1 : false)

foreach size : [['int', 'SIZEOF_INT'], ['long', 'SIZEOF_LONG'],
                ['long long', 'SIZEOF_LONG_LONG'], ['void*', 'SIZEOF_VOID_P']]
  conf.set(size[1], cc.sizeof(size[0]))
endforeach

# Two plugins reach for Core Foundation on Apple platforms, and nowhere else.
apple_corefoundation = []
apple_security = []
openssl_deps = []
platform_deps = []
if is_darwin
  apple_corefoundation = [dependency('appleframeworks', modules: ['CoreFoundation'])]
  apple_security = [dependency('appleframeworks', modules: ['CoreFoundation', 'Security'])]
  frameworks = ['Foundation', 'CoreFoundation', 'CoreGraphics']
  if not is_ios
    # For the save panel the file dialog puts up, which iOS has no equivalent of.
    frameworks += 'AppKit'
  endif
  platform_deps += dependency('appleframeworks', modules: frameworks)
endif

if not is_darwin and not is_windows
  openssl_deps = [dependency('openssl')]
endif

dl_dep = cc.find_library('dl', required: false)
m_dep = cc.find_library('m', required: false)
uuid_dep = cc.find_library('uuid', required: not (is_darwin or is_windows))
thread_dep = dependency('threads')
ffi_dep = dependency('libffi')

conf.set('HAVE_LIBDL', dl_dep.found() ? 1 : false)
conf.set('HAVE_UUID_GENERATE',
  cc.has_function('uuid_generate', dependencies: uuid_dep) ? 1 : false)
conf.set('HAVE_UUIDGEN',
  cc.has_function('uuidgen', dependencies: uuid_dep) ? 1 : false)

# Upstream's template with one entry added, read the way CMake reads it. The
# addition is the endianness: see the comment beside it.
config_h = configure_file(
  input: 'swifty-config.h.in',
  output: 'config.h',
  configuration: conf,
  format: 'cmake@',
)

# Installed under a name of its own: "config.h" is too common a thing to put on
# every consumer's include path, and the path has to be there for the headers
# that reach for each other unqualified.
configure_file(
  input: 'swifty-config.h.in',
  output: 'pharovmConfig.h',
  configuration: conf,
  format: 'cmake@',
  install: true,
  install_dir: get_option('includedir') / 'pharovm',
)

core_includes = include_directories(
  '.',
  'include',
  'include/pharovm',
  'include/pharovm/common',
  'include/pharovm/ffi',
  'include/pharovm/semaphores',
  'include/pharovm/' + platform_dir,
  generated / 'vm/include',
)

interpreter_sources = flavour == 'CoInterpreter' \
  ? [generated / 'vm/src/gcc3x-cointerp.c', generated / 'vm/src/cogit.c'] \
  : [generated / 'vm/src/gcc3x-interp.c']

support_sources = files(
  'src/debug.c',
  'src/utils.c',
  'src/errorCode.c',
  'src/externalPrimitives.c',
  'src/client.c',
  'src/pathUtilities.c',
  'src/fileDialogCommon.c',
  'src/stringUtilities.c',
  'src/imageAccess.c',
  'src/parameters/parameterVector.c',
  'src/parameters/parameters.c',
  'src/semaphores/platformSemaphore.c',
  'src/common/heartbeat.c',
  'src/common/sqHeapMap.c',
  'src/common/sqVirtualMachine.c',
  'src/common/sqNamedPrims.c',
  'src/common/sqExternalSemaphores.c',
  'src/common/sqTicker.c',
)

ffi_sources = files(
  'src/ffi/functionDefinitionPrimitives.c',
  'src/ffi/primitiveCalls.c',
  'src/ffi/primitiveUtils.c',
  'src/ffi/types.c',
  'src/ffi/typesPrimitives.c',
  'src/ffi/utils.c',
  'src/ffi/sameThread/sameThread.c',
  'src/ffi/callbacks/callbackPrimitives.c',
  'src/ffi/callbacks/callbacks.c',
  'src/semaphores/pharoSemaphore.c',
  'src/threadSafeQueue/threadSafeQueue.c',
  'src/ffi/pThreadedFFI.c',
  'src/ffi/worker/worker.c',
  'src/ffi/worker/workerPrimitives.c',
  'src/ffi/worker/workerTask.c',
)

platform_sources = files('src/unix/aio.c', 'src/unix/debugUnix.c',
                         'src/unix/memoryUnix.c', 'src/unix/fileDialogUnix.c')
if is_windows
  platform_sources = files('src/win/aio.c', 'src/win/debugWin.c',
                           'src/win/memoryWin.c', 'src/win/fileDialogWin.c')
elif is_darwin
  add_languages('objc', 'objcpp', native: false)
  platform_sources = files('src/osx/aioOSX.c', 'src/osx/utilsMac.mm',
                           'src/unix/debugUnix.c', 'src/parameters/parameters.m',
                           'src/unix/memoryUnix.c')
  # fileDialogUnix.c answers vm_file_dialog_is_nop as true, which is the only
  # honest answer on a platform with no save panel.
  platform_sources += is_ios ? files('src/unix/fileDialogUnix.c') \
                             : files('src/osx/fileDialogMac.m')
endif

# Upstream compiles these into everything, and the plugins are built against the
# same headers as the core, so they have to agree.
common_args = [
  '-DIMMUTABILITY=1',
  '-DCOGMTVM=0',
  '-DDEBUGVM=0',
  '-D_FILE_OFFSET_BITS=64',
  '-DSOURCE_PATH_SIZE=0',
  '-DLSB_FIRST=@0@'.format(lsb_first),
]
if flavour == 'CoInterpreter'
  common_args += '-DASYNC_FFI_QUEUE=1'
endif
common_args += cc.get_supported_arguments(
  '-Wno-int-conversion',
  '-Wno-pointer-sign',
  '-Wno-pointer-to-int-cast',
  '-Wno-incompatible-pointer-types',
  '-Wno-implicit-function-declaration',
  '-Wno-sometimes-uninitialized',
  '-Wno-unknown-pragmas',
  '-Wno-deprecated-declarations',
  '-Wno-compare-distinct-pointer-types',
)

# Upstream keeps these to the core alone. They decide how memory is reached and
# what the FFI structures look like, so handing them to a plugin as well would
# have the two disagree about the same headers.
core_args = common_args + [
  '-DFEATURE_FFI=1',
  '-DFEATURE_THREADED_FFI=1',
  '-DUSE_INLINE_MEMORY_ACCESSORS=1',
]

# iOS withholds writable-executable memory, so it takes the interpreter with no
# code generator in it at all -- and the SIMD support is the JIT's.
if flavour == 'CoInterpreter'
  core_args += '-DFEATURE_JIT_SIMD=1'
endif

# Apple Silicon will not have memory writable and executable at once, so the JIT
# has to unprotect its code zone around every write. Without this the VM stores
# straight into it and takes a bus error before the image is up. Harmless where
# the rule is not enforced: the calls it turns on are no-ops there.
if is_darwin
  core_args += '-DREAD_ONLY_CODE_ZONE=1'
endif

# ioLoadModule() falls back to dlopen()ing a plugin by leaf name, which dyld
# resolves through the rpaths of whoever called it -- the core. Naming itself
# lets it find the plugins sitting beside it wherever the two are put.
core = shared_library('PharoVMCore',
  support_sources, ffi_sources, platform_sources, interpreter_sources, config_h,
  include_directories: core_includes,
  c_args: core_args,
  dependencies: [ffi_dep, thread_dep, dl_dep, m_dep] + platform_deps,
  install: true,
  install_rpath: is_darwin ? '@loader_path' : '',
)

core_dep = declare_dependency(
  link_with: core,
  include_directories: core_includes,
  sources: config_h,
)

# The CLI that runs an image. iOS has no command line to run it from, and the
# image build needs a VM of the very format it is about to ship.
if not is_ios
  executable('Pharo',
    files('src/unix/unixMain.c'),
    include_directories: core_includes,
    c_args: common_args,
    link_with: core,
    install: true,
    install_rpath: is_darwin ? '@executable_path/../lib' : '$ORIGIN/../lib',
  )
endif

# Every plugin is the same shape: common sources, the platform's own, and for
# some of them the primitives Slang wrote.
# name, Slang wrote its primitives, takes the unix sources on Apple too, the
# plugins it builds on, extras
plugins = [
  ['FilePlugin', true, true, [], apple_corefoundation],
  ['NewFilePlugin', true, true, [], []],
  ['FileAttributesPlugin', false, true, ['FilePlugin'], []],
  ['SocketPlugin', false, false, [], []],
  ['UUIDPlugin', false, false, [], [uuid_dep]],
  ['LocalePlugin', false, true, [], apple_corefoundation],
  ['LargeIntegers', false, false, [], []],
  ['MiscPrimitivePlugin', false, false, [], []],
  ['BitBltPlugin', false, false, [], []],
  ['SurfacePlugin', true, false, [], []],
  ['FloatArrayPlugin', true, false, [], []],
]

# iOS makes only what the image cannot start without: the rest are a desktop's
# business, and SqueakSSL's Mac sources reach for keychain search keys iOS
# withholds.
if not is_ios
  plugins += [
    ['JPEGReaderPlugin', false, false, [], []],
    ['JPEGReadWriter2Plugin', false, false, [], []],
    ['DSAPrims', false, false, [], []],
    ['B2DPlugin', false, false, [], []],
    ['SqueakSSL', false, false, [], is_darwin ? apple_security : openssl_deps],
  ]
  if not is_windows
    plugins += [['UnixOSProcessPlugin', false, false,
                 ['FilePlugin', 'SocketPlugin'], []]]
  endif
endif


built_plugins = {}

foreach plugin : plugins
  name = plugin[0]
  sources = []

  # UUIDPlugin keeps its sources directly under common/, unlike every other.
  common = fs.is_dir('plugins' / name / 'src/common') \
    ? 'plugins' / name / 'src/common' \
    : 'plugins' / name / 'common'

  platform_dirs = [platform_dir]
  if is_darwin and plugin[2]
    platform_dirs += 'unix'
  endif

  source_dirs = [common]
  foreach where : platform_dirs
    source_dirs += 'plugins' / name / 'src' / where
  endforeach

  foreach dir : source_dirs
    if fs.is_dir(dir)
      sources += files(run_command(
        'sh', '-c', 'ls @0@/*.c 2>/dev/null || true'.format(
          meson.current_source_dir() / dir),
        check: true).stdout().strip().split('\n'))
    endif
  endforeach

  if plugin[1]
    sources += generated / 'plugins/src' / name / (name + '.c')
  endif

  include_dirs = ['plugins' / name / 'include/common']
  foreach where : platform_dirs
    include_dirs += 'plugins' / name / 'include' / where
  endforeach

  plugin_includes = [core_includes]
  foreach dir : include_dirs
    if fs.is_dir(dir)
      plugin_includes += include_directories(dir)
    endif
  endforeach

  # A plugin that does its own arithmetic needs libm named on its own link line:
  # off Darwin, an indirect shared library resolves nothing.
  plugin_deps = [core_dep, m_dep] + plugin[4]
  foreach needed : plugin[3]
    plugin_deps += built_plugins[needed]
  endforeach

  library = shared_library(name, sources,
    include_directories: plugin_includes,
    c_args: common_args,
    dependencies: plugin_deps,
    install: true,
    install_rpath: is_darwin ? '@loader_path' : '',
  )
  built_plugins += {name: declare_dependency(
    link_with: library, include_directories: plugin_includes)}
endforeach

# Upstream's own layout, kept as it stands: the headers reach for each other
# both unqualified and through "pharovm/...", and both resolve against it. The
# framework on Apple platforms flattens them instead and rewrites the paths,
# which is a staging trick this build has no need of.
install_subdir('include/pharovm',
  install_dir: get_option('includedir'),
  exclude_files: ['config.h.in'],
)
install_data(
  run_command('sh', '-c', 'ls @0@/vm/include/*.h'.format(generated_abs),
    check: true).stdout().strip().split('\n'),
  install_dir: get_option('includedir') / 'pharovm',
)

meson.add_install_script('sh', '-c',
  'cd "${MESON_INSTALL_DESTDIR_PREFIX}/include/pharovm" && ' +
  'grep -rl \'#include "config.h"\' . | ' +
  'xargs perl -pi -e \'s|#include\\s*"config\\.h"|#include "pharovmConfig.h"|\'')

pkg.generate(core,
  name: 'pharo-vm',
  description: 'Pharo virtual machine core',
  subdirs: ['.', 'pharovm', 'pharovm/common', 'pharovm/' + platform_dir],
)
