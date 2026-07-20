// swift-tools-version: 5.9
import Foundation
import PackageDescription

// A locally built VM (see tools/build-vm.sh) short-circuits the published
// artifact, mirroring how r2pharo/frida-pharo honour R2PHARO_LIB/FRIDA_CORE_LIB.
// SwiftPM only accepts binary paths under the package root, so this is relative.
let localVMRoot = ProcessInfo.processInfo.environment["PHARO_VM_ROOT"]

let vmVersion = "20260721.1"

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
        checksum: "95300d2233627c2b256b20c18e6caabd6e1a6d9fa77b419684bdb3ce9af23373"
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
