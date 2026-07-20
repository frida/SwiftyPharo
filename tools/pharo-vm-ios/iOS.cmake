# pharo-vm ships no iOS platform file. Mirrors Darwin.cmake without AppKit and
# CoreGraphics, whose only user is the image-picker dialog.

# Platform detection only recognises "Darwin".
set(OSX 1)

set(CMAKE_INSTALL_RPATH "@executable_path/Frameworks")
set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)

function(add_platform_headers)
  target_include_directories(${VM_LIBRARY_NAME}
    PUBLIC
      ${CMAKE_CURRENT_SOURCE_DIR}/include/pharovm/osx
      ${CMAKE_CURRENT_SOURCE_DIR}/include/pharovm/unix
      ${CMAKE_CURRENT_SOURCE_DIR}/include/pharovm/common
    )
endfunction() #add_platform_headers

set(EXTRACTED_SOURCES
    #Platform sources
    ${CMAKE_CURRENT_SOURCE_DIR}/src/osx/aioOSX.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/osx/utilsMac.mm
    ${CMAKE_CURRENT_SOURCE_DIR}/src/unix/debugUnix.c

    # Answers vm_file_dialog_is_nop as true.
    ${CMAKE_CURRENT_SOURCE_DIR}/src/unix/fileDialogUnix.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/parameters/parameters.m

    #Virtual Memory functions
    ${CMAKE_CURRENT_SOURCE_DIR}/src/unix/memoryUnix.c
)

set(VM_FRONTEND_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/src/unix/unixMain.c
)

configure_file(resources/mac/Info.plist.in build/includes/Info.plist)

macro(add_third_party_dependencies_per_platform)
endmacro()

macro(configure_installables INSTALL_COMPONENT)
  install(
    DIRECTORY "${CMAKE_BINARY_DIR}/build/vm/Debug/"
    DESTINATION "./"
    USE_SOURCE_PERMISSIONS
    COMPONENT ${INSTALL_COMPONENT})
endmacro()

macro(add_required_libs_per_platform)
  target_link_libraries(${VM_LIBRARY_NAME} "-framework Foundation")
endmacro()

execute_process(
    COMMAND xcrun --sdk ${CMAKE_OSX_SYSROOT} --show-sdk-path
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    OUTPUT_VARIABLE OSX_SDK_PATH
    OUTPUT_STRIP_TRAILING_WHITESPACE)
