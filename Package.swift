// swift-tools-version: 5.9
import Foundation
import PackageDescription

// A locally built VM (see tools/build-vm.sh) short-circuits the published
// artifact, mirroring how r2pharo/frida-pharo honour R2PHARO_LIB/FRIDA_CORE_LIB.
// SwiftPM only accepts binary paths under the package root, so this is relative.
let localVMRoot = ProcessInfo.processInfo.environment["PHARO_VM_ROOT"]

let vmVersion = "20261120.1"

let pharoVMTarget: Target
if let localVMRoot {
    pharoVMTarget = .binaryTarget(name: "PharoVM", path: localVMRoot)
} else {
    #if canImport(Darwin)
    pharoVMTarget = .binaryTarget(
        name: "PharoVM",
        url: "https://github.com/frida/SwiftyPharo/releases/download/vm-\(vmVersion)/PharoVM.xcframework.zip",
        checksum: "0ba722dcc95ff4e1217d19f9660c363b3f19bf307a030925713d9ca3d52f994c"
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
            // SwiftPM reads a pkg-config search path the way a unix shell writes
            // one, which no path with a drive letter in it survives, so nothing
            // the .pc names reaches the linker here.
            linkerSettings: [.linkedLibrary("PharoVMCore", .when(platforms: [.windows]))]
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
