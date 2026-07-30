import Foundation

/// A live object in the image, kept alive until released.
public struct PharoObject: Sendable, Decodable {
    public let handle: Int
    public let printString: String
    public let className: String
    public let isClass: Bool

    private enum CodingKeys: String, CodingKey {
        case handle
        case printString
        case className = "class"
        case isClass
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

    public init(
        viewName: String,
        title: String,
        priority: Int,
        methodSelector: String,
        columns: [String]? = nil,
        text: String? = nil
    ) {
        self.viewName = viewName
        self.title = title
        self.priority = priority
        self.methodSelector = methodSelector
        self.columns = columns
        self.text = text
    }
}

public struct PharoItemsPage: Sendable, Decodable {
    public let total: Int
    /// A row per item, a cell per column the view declares.
    public let items: [[PharoCell]]
}

/// A class named in a piece of source, and where it sits, so an editor can
/// offer to open it without parsing Smalltalk itself. Positions are 1-based
/// and inclusive, the way the image counts them.
public struct PharoClassReference: Sendable, Decodable {
    public let name: String
    public let start: Int
    public let stop: Int
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

struct PharoClassReferenceList: Decodable {
    let references: [PharoClassReference]
}

/// Fuel bytes, which arrive base64 encoded, which is what Data decodes from.
struct PharoBlob: Decodable {
    let data: Data
}

/// A class laid bare for browsing: where it sits, and every method it holds
/// with the source to show when one is opened.
public struct PharoClassBrowserInfo: Sendable, Decodable {
    public let name: String
    public let superclass: String
    public let package: String
    public let tag: String
    public let definition: String
    public let comment: String
    public let methods: [PharoMethodInfo]
}

public struct PharoMethodInfo: Sendable, Decodable, Identifiable {
    public let selector: String
    public let side: String
    public let category: String
    public let source: String

    public var id: String { "\(side)>>\(selector)" }
}

/// A method a piece of source sends, and where its selector ends, so an editor
/// can offer to open the method sent there. Positions are 1-based, inclusive.
public struct PharoMethodReference: Sendable, Decodable, Identifiable {
    public let selector: String
    public let stop: Int
    public let className: String
    public let side: String
    public let category: String
    public let source: String

    public var id: String { "\(className)>>\(side)>>\(selector)@\(stop)" }

    private enum CodingKeys: String, CodingKey {
        case selector
        case stop
        case className = "class"
        case side
        case category
        case source
    }
}

struct PharoMethodReferenceList: Decodable {
    let references: [PharoMethodReference]
}

/// A capitalized name in a piece of source that no global answers to, with the
/// nearest existing class names as corrections. Positions are 1-based, inclusive.
public struct PharoUndeclaredVariable: Sendable, Decodable, Identifiable {
    public let name: String
    public let start: Int
    public let stop: Int
    public let suggestions: [String]

    public var id: String { "\(name)@\(start)" }
}

struct PharoUndeclaredVariableList: Decodable {
    let variables: [PharoUndeclaredVariable]
}

/// A run of source that gets a colour, the way Glamorous Toolkit's coder styles
/// it. Positions are 1-based, inclusive; each colour is RRGGBB hex, one for the
/// light theme and one for the dark.
public struct PharoStyleSpan: Sendable, Decodable {
    public let start: Int
    public let stop: Int
    public let light: String?
    public let dark: String?
    public let bold: Bool
}

struct PharoStyleSpanList: Decodable {
    let spans: [PharoStyleSpan]
}
