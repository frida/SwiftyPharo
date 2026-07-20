import CPharoVM
import Foundation

public enum PharoRuntimeState: Sendable {
    case starting
    case running
    case imageLoadFailed
    case threadSpawnFailed
}

public enum PharoRuntimeError: Error, Sendable {
    case imageLoadFailed
    case threadSpawnFailed
}

/// One per process: the VM keeps its state in globals inside libPharoVMCore.
public final class PharoRuntime: @unchecked Sendable {
    public static let shared = PharoRuntime()

    static let requestQueue = DispatchQueue(label: "swiftypharo.requests")

    public var state: PharoRuntimeState {
        PharoRuntimeState(swifty_pharo_state())
    }

    /// Starts the interpreter on its own thread and returns at once; await
    /// `runningState()` to learn whether the image loaded. `plugins` holds
    /// libFilePlugin and friends, which the VM resolves as the image asks.
    public func boot(image: URL, plugins: URL) {
        let arguments = retainedArgumentVector(for: image)
        let environment = retainedEnvironmentVector()

        swifty_pharo_boot(
            image.path,
            plugins.path,
            Int32(arguments.count),
            arguments.baseAddress,
            environment.baseAddress)
    }

    @available(macOS 12, iOS 15, *)
    public func runningState() async throws {
        while true {
            switch state {
            case .running:
                return
            case .imageLoadFailed:
                throw PharoRuntimeError.imageLoadFailed
            case .threadSpawnFailed:
                throw PharoRuntimeError.threadSpawnFailed
            case .starting:
                try await Task.sleep(nanoseconds: 5_000_000)
            }
        }
    }

    /// Never released: the VM reads these for its lifetime.
    private func retainedArgumentVector(for image: URL) -> UnsafeMutableBufferPointer<UnsafePointer<CChar>?> {
        retainedVector(of: [ProcessInfo.processInfo.arguments.first ?? "swifty-pharo", image.path])
    }

    private func retainedEnvironmentVector() -> UnsafeMutableBufferPointer<UnsafePointer<CChar>?> {
        retainedVector(of: ProcessInfo.processInfo.environment.map { "\($0.key)=\($0.value)" })
    }

    private func retainedVector(of values: [String]) -> UnsafeMutableBufferPointer<UnsafePointer<CChar>?> {
        let vector = UnsafeMutableBufferPointer<UnsafePointer<CChar>?>.allocate(capacity: values.count + 1)
        for (index, value) in values.enumerated() {
            vector[index] = UnsafePointer(retainedCopy(of: value))
        }
        vector[values.count] = nil
        return vector
    }

    private func retainedCopy(of value: String) -> UnsafeMutablePointer<CChar> {
        let characters = Array(value.utf8CString)
        let copy = UnsafeMutablePointer<CChar>.allocate(capacity: characters.count)
        copy.update(from: characters, count: characters.count)
        return copy
    }
}

extension PharoRuntimeState {
    init(_ state: SwiftyPharoState) {
        switch state {
        case SwiftyPharoStateRunning:
            self = .running
        case SwiftyPharoStateImageLoadFailed:
            self = .imageLoadFailed
        case SwiftyPharoStateThreadSpawnFailed:
            self = .threadSpawnFailed
        default:
            self = .starting
        }
    }
}
