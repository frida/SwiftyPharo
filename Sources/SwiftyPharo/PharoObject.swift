import Foundation

/// A live object in the image, kept alive until released.
public struct PharoObject: Sendable, Decodable {
    public let handle: Int
    public let printString: String
    public let className: String

    private enum CodingKeys: String, CodingKey {
        case handle
        case printString
        case className = "class"
    }
}

/// A view an object declares about itself through a `<gtView>` method.
public struct PharoViewDeclaration: Sendable, Decodable {
    public let viewName: String
    public let title: String
    public let priority: Int
    public let methodSelector: String
    public let columns: [String]?
    public let text: String?
}

public struct PharoItemsPage: Sendable, Decodable {
    public let total: Int
    /// A row per item, a cell per column the view declares.
    public let items: [[PharoCell]]
}

/// Candidates for the token the cursor sits in, which starts at `tokenStart`
/// so a caller knows how much of its source each candidate replaces.
public struct PharoCompletions: Sendable, Decodable {
    public let tokenStart: Int
    public let completions: [String]
}

/// Either words or a picture, which is as much as a column can hold. `png`
/// arrives base64 encoded, which is what Data decodes from by default.
public struct PharoCell: Sendable, Decodable {
    public let text: String?
    public let png: Data?
}

extension PharoCell: CustomStringConvertible {
    public var description: String {
        if let text { return text }
        if let png { return "<png \(png.count) bytes>" }
        return ""
    }
}

public enum PharoRequestError: Error, Sendable {
    case imageFailed(String)
    case bridgeUnavailable
}

extension PharoRequestError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .imageFailed(let message):
            message
        case .bridgeUnavailable:
            "The image stopped answering"
        }
    }
}

struct PharoFailure: Decodable {
    let error: String
    let message: String?
}

struct PharoViewList: Decodable {
    let views: [PharoViewDeclaration]
}
