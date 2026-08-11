// swift-tools-version: 5.9
import Foundation
import PackageDescription

// A locally built VM (see tools/build-vm.sh) short-circuits the published
// artifact, mirroring how r2pharo/frida-pharo honour R2PHARO_LIB/FRIDA_CORE_LIB.
// SwiftPM only accepts binary paths under the package root, so this is relative.
let localVMRoot = ProcessInfo.processInfo.environment["PHARO_VM_ROOT"]

let vmVersion = "20260811.3"

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
        checksum: "ee48309aefb7577f62217fa86d7e43d391289525e25288a3c734086283f1054b"
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
            dependencies: ["PharoVM"]
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
