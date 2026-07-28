import CPharoVM
import Foundation

@available(macOS 12, iOS 15, *)
extension PharoRuntime {
    public func evaluate(_ source: String) async throws -> PharoObject {
        try await send(["op": "evaluate", "source": source])
    }

    public func views(of anObject: PharoObject) async throws -> [PharoViewDeclaration] {
        let list: PharoViewList = try await send(["op": "views", "handle": anObject.handle])
        return list.views
    }

    public func items(
        of anObject: PharoObject,
        view: String,
        from: Int,
        count: Int
    ) async throws -> PharoItemsPage {
        try await send([
            "op": "items",
            "handle": anObject.handle,
            "view": view,
            "from": from,
            "count": count,
        ])
    }

    public func drillInto(
        _ anObject: PharoObject,
        view: String,
        index: Int
    ) async throws -> PharoObject {
        try await send(["op": "send", "handle": anObject.handle, "view": view, "index": index])
    }

    public func completions(for source: String, at position: Int) async throws -> PharoCompletions {
        try await send(["op": "complete", "source": source, "position": position])
    }

    public func classReferences(in source: String) async throws -> [PharoClassReference] {
        let found: PharoClassReferenceList = try await send(["op": "classReferences", "source": source])
        return found.references
    }

    /// The methods a piece of source sends to a receiver whose class is known:
    /// a class named outright, or self and super within a method of `selfClass`.
    public func methodReferences(in source: String, selfClass: String?) async throws -> [PharoMethodReference] {
        let found: PharoMethodReferenceList = try await send([
            "op": "methodReferences",
            "source": source,
            "selfClass": selfClass as Any,
        ])
        return found.references
    }

    public func classBrowser(of anObject: PharoObject) async throws -> PharoClassBrowserInfo {
        try await send(["op": "classBrowser", "handle": anObject.handle])
    }

    /// Compiles source into the class, on the side and under the category the
    /// method belongs to, and answers the method as it now stands.
    public func compileMethod(
        in aClass: PharoObject,
        side: String,
        category: String,
        source: String
    ) async throws -> PharoMethodInfo {
        try await send([
            "op": "compileMethod",
            "handle": aClass.handle,
            "side": side,
            "category": category,
            "source": source,
        ])
    }

    /// Fuel bytes for the object, so a later session can bring it back to life.
    public func serialize(_ anObject: PharoObject) async throws -> Data {
        let blob: PharoBlob = try await send(["op": "serialize", "handle": anObject.handle])
        return blob.data
    }

    public func materialize(_ data: Data) async throws -> PharoObject {
        try await send(["op": "materialize", "data": data.base64EncodedString()])
    }

    public func release(_ anObject: PharoObject) async throws {
        let _: PharoReleased = try await send(["op": "release", "handle": anObject.handle])
    }

    private func send<Answer: Decodable>(_ request: [String: Any]) async throws -> Answer {
        let reply = try await requestJSON(String(
            data: try JSONSerialization.data(withJSONObject: request),
            encoding: .utf8)!)

        let payload = Data(reply.utf8)
        if let failure = try? JSONDecoder().decode(PharoFailure.self, from: payload) {
            throw PharoRequestError.imageFailed(failure.message ?? failure.error)
        }
        return try JSONDecoder().decode(Answer.self, from: payload)
    }

    /// The image serves one request at a time, and each blocks until it answers.
    private func requestJSON(_ request: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            PharoRuntime.requestQueue.async {
                continuation.resume(with: Result { try PharoRuntime.callImage(request) })
            }
        }
    }

    private static func callImage(_ request: String) throws -> String {
        var capacity = 64 * 1024
        while true {
            var response = [CChar](repeating: 0, count: capacity)
            let length = Int(swifty_pharo_request(request, &response, Int32(capacity)))
            if length == Int(SWIFTY_PHARO_BRIDGE_UNAVAILABLE) {
                throw PharoRequestError.bridgeUnavailable
            }
            if length < capacity {
                return String(cString: response)
            }
            capacity = length + 1
        }
    }
}

struct PharoReleased: Decodable {
    let released: Int
}
