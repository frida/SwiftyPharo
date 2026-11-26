import CPharoVM
import Foundation

final class PharoRequests: @unchecked Sendable {
    static let shared = PharoRequests()

    private let postQueue = DispatchQueue(label: "swiftypharo.requests", qos: .default)
    private let lock = NSLock()
    private var lastID: Int64 = 0
    private var awaiting: [Int64: CheckedContinuation<String, any Error>] = [:]

    private init() {
        swifty_pharo_receive_replies { request, reply in
            PharoRequests.shared.settle(request, with: reply.map { .success(String(cString: $0)) } ?? .failure(PharoRequestError.interrupted))
        }
    }

    func reply(to request: [String: Any]) async throws -> String {
        let id = nextID()
        let message = try Self.encode(["id": id, "request": request])
        let interrupt = try Self.encode(["interrupt": id])
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                lock.lock()
                defer { lock.unlock() }
                guard !Task.isCancelled else {
                    return continuation.resume(throwing: PharoRequestError.interrupted)
                }
                awaiting[id] = continuation
                post(message, failing: id)
            }
        } onCancel: {
            lock.lock()
            defer { lock.unlock() }
            guard awaiting[id] != nil else { return }
            post(interrupt, failing: nil)
        }
    }

    private func nextID() -> Int64 {
        lock.lock()
        defer { lock.unlock() }
        lastID += 1
        return lastID
    }

    private func post(_ message: String, failing id: Int64?) {
        postQueue.async {
            guard swifty_pharo_post(message) == SWIFTY_PHARO_BRIDGE_UNAVAILABLE, let id else { return }
            self.settle(id, with: .failure(PharoRequestError.bridgeUnavailable))
        }
    }

    private func settle(_ id: Int64, with outcome: Result<String, any Error>) {
        lock.lock()
        let continuation = awaiting.removeValue(forKey: id)!
        lock.unlock()
        continuation.resume(with: outcome)
    }

    private static func encode(_ message: [String: Any]) throws -> String {
        String(data: try JSONSerialization.data(withJSONObject: message), encoding: .utf8)!
    }
}
