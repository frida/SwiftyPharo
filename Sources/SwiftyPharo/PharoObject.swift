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
    public let items: [String]
}

public enum PharoRequestError: Error, Sendable {
    case imageFailed(String)
    case bridgeUnavailable
}

struct PharoFailure: Decodable {
    let error: String
    let message: String?
}

struct PharoViewList: Decodable {
    let views: [PharoViewDeclaration]
}
