// swift-tools-version: 5.9
import Foundation
import PackageDescription

// A locally built VM (see tools/build-vm.sh) short-circuits the published
// artifact, mirroring how r2pharo/frida-pharo honour R2PHARO_LIB/FRIDA_CORE_LIB.
// SwiftPM only accepts binary paths under the package root, so this is relative.
let localVMRoot = ProcessInfo.processInfo.environment["PHARO_VM_ROOT"]

let vmVersion = "20260810.1"

let pharoVMTarget: Target
if let localVMRoot {
    pharoVMTarget = .binaryTarget(name: "PharoVM", path: localVMRoot)
} else {
    #if os(Windows)
    pharoVMTarget = .systemLibrary(name: "PharoVM", path: "Sources/PharoVM")
    #elseif canImport(Darwin)
    pharoVMTarget = .binaryTarget(
        name: "PharoVM",
        url: "https://github.com/frida/SwiftyPharo/releases/download/vm-\(vmVersion)/PharoVM.xcframework.zip",
        checksum: "e401eaf16c5302135625c7aad60aa6e4e6129bbec76cada33809190fa598f543"
    )
    #else
    pharoVMTarget = .systemLibrary(
        name: "PharoVM",
        path: "Sources/PharoVM",
        pkgConfig: "pharo-vm"
    )
    #endif
}

let package = Package(
    name: "SwiftyPharo",
    platforms: [
        .macOS(.v11),
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "SwiftyPharo",
            targets: ["SwiftyPharo"]
        )
    ],
    targets: [
        pharoVMTarget,

        .target(
            name: "CPharoVM",
            dependencies: ["PharoVM"],
            // pharo-vm sets this as a compile definition and records it in no
            // header, so unix/sqConfig.h refuses to compile without it. The
            // Apple headers read the endianness the compiler already declares.
            cSettings: [
                .define("LSB_FIRST", to: "1", .when(platforms: [.linux, .windows, .android]))
            ]
        ),

        .target(
            name: "SwiftyPharo",
            dependencies: ["CPharoVM"]
        ),

        .executableTarget(
            name: "swifty-pharo-probe",
            dependencies: ["SwiftyPharo"]
        ),

        .testTarget(
            name: "SwiftyPharoTests",
            dependencies: ["SwiftyPharo"]
        ),
    ]
)
