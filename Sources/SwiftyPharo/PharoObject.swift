import Foundation

/// A live object in the image, kept alive until released.
public struct PharoObject: Sendable, Decodable {
    public let handle: Int
    public let printString: String
    public let className: String
    public let isClass: Bool
    /// How Glamorous Toolkit names the object beside its class: its print string
    /// for most, an item count and elements for a collection.
    public let display: String

    private enum CodingKeys: String, CodingKey {
        case handle
        case printString
        case className = "class"
        case isClass
        case display
    }
}

/// A view an object declares about itself through a `<gtView>` method.
public struct PharoViewDeclaration: Sendable, Decodable {
    public let viewName: String
    public let title: String
    public let priority: Double
    public let methodSelector: String
    public let columns: [PharoColumn]?
    public let text: String?
    public let graph: PharoGraph?
    public let chart: PharoChart?
    public let canvas: PharoCanvasReference?

    public init(
        viewName: String,
        title: String,
        priority: Double,
        methodSelector: String,
        columns: [PharoColumn]? = nil,
        text: String? = nil,
        graph: PharoGraph? = nil,
        chart: PharoChart? = nil,
        canvas: PharoCanvasReference? = nil
    ) {
        self.viewName = viewName
        self.title = title
        self.priority = priority
        self.methodSelector = methodSelector
        self.columns = columns
        self.text = text
        self.graph = graph
        self.chart = chart
        self.canvas = canvas
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let methodSelector = try container.decode(String.self, forKey: .methodSelector)
        do {
            self.init(
                viewName: try container.decode(String.self, forKey: .viewName),
                title: try container.decode(String.self, forKey: .title),
                priority: try container.decode(Double.self, forKey: .priority),
                methodSelector: methodSelector,
                columns: try container.decodeIfPresent([PharoColumn].self, forKey: .columns),
                text: try container.decodeIfPresent(String.self, forKey: .text),
                graph: try container.decodeIfPresent(PharoGraph.self, forKey: .graph),
                chart: try container.decodeIfPresent(PharoChart.self, forKey: .chart),
                canvas: try container.decodeIfPresent(PharoCanvasReference.self, forKey: .canvas))
        } catch let error as DecodingError {
            self.init(
                viewName: "text",
                title: (try? container.decode(String.self, forKey: .title)).map { "\($0) (Error)" } ?? "Error",
                priority: (try? container.decode(Double.self, forKey: .priority)) ?? 75,
                methodSelector: methodSelector,
                text: "\(methodSelector) \(Self.reason(for: error, below: decoder.codingPath))")
        }
    }

    private enum CodingKeys: String, CodingKey {
        case viewName
        case title
        case priority
        case methodSelector
        case columns
        case text
        case graph
        case chart
        case canvas
    }

    private static func reason(for error: DecodingError, below path: [any CodingKey]) -> String {
        switch error {
        case .keyNotFound(let key, _):
            return "declared no \(key.stringValue)"
        case .typeMismatch(_, let context), .valueNotFound(_, let context), .dataCorrupted(let context):
            let field = context.codingPath.dropFirst(path.count).map(\.stringValue).joined(separator: ".")
            return "declared a \(field) that cannot be shown: \(context.debugDescription)"
        @unknown default:
            return "declared what cannot be shown: \(error)"
        }
    }
}

public struct PharoColumn: Sendable, Decodable, Equatable {
    public let title: String
    public let width: PharoColumnWidth?
    public let minimumCharacters: Int?
    public let priority: Double?

    public init(title: String, width: PharoColumnWidth? = nil, minimumCharacters: Int? = nil, priority: Double? = nil) {
        self.title = title
        self.width = width
        self.minimumCharacters = minimumCharacters
        self.priority = priority
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            title: try container.decode(String.self, forKey: .title),
            width: try Self.width(in: container),
            minimumCharacters: try container.decodeIfPresent(Int.self, forKey: .minimumCharacters),
            priority: try container.decodeIfPresent(Double.self, forKey: .priority))
    }

    public var isDeclared: Bool {
        width != nil || minimumCharacters != nil || priority != nil
    }

    private enum CodingKeys: String, CodingKey {
        case title
        case fitContent
        case weight
        case width
        case minimumCharacters
        case priority
    }

    private static func width(in container: KeyedDecodingContainer<CodingKeys>) throws -> PharoColumnWidth? {
        if try container.decodeIfPresent(Bool.self, forKey: .fitContent) == true { return .fitContent }
        if let weight = try container.decodeIfPresent(Double.self, forKey: .weight) { return .weight(weight) }
        if let points = try container.decodeIfPresent(Double.self, forKey: .width) { return .points(points) }
        return nil
    }
}

public enum PharoColumnWidth: Sendable, Equatable {
    case fitContent
    case weight(Double)
    case points(Double)
}

/// A view the host draws itself, from a scene it already holds. Only which
/// scene travels: the drawing never enters the image.
public struct PharoCanvasReference: Sendable, Codable, Equatable {
    public let scene: Int

    public init(scene: Int) {
        self.scene = scene
    }
}

/// A GtPlotter chart: one or more series over a shared pair of axes, each axis
/// linear or logarithmic. Clicking a point drills into the element behind it.
public struct PharoChart: Sendable, Codable, Equatable {
    public let scaleX: String
    public let scaleY: String
    public let titleX: String
    public let titleY: String
    public let series: [PharoChartSeries]
}

/// One run of points drawn one way -- bars along or up the frame, a line, or
/// scattered dots.
public struct PharoChartSeries: Sendable, Codable, Equatable {
    public let kind: String
    public let orientation: String
    public let points: [PharoChartPoint]
}

public struct PharoChartPoint: Sendable, Codable, Equatable {
    public let label: String
    public let x: Double
    public let y: Double
}

/// A graph a `mondrian` view paints: nodes, the directed edges between them by
/// index, and the layout that arranges them. Clicking a node drills into the
/// object behind it, the way it drills into a list row.
public struct PharoGraph: Sendable, Codable, Equatable {
    public let layout: String
    public let nodes: [PharoGraphNode]
    public let edges: [PharoGraphEdge]
}

public struct PharoGraphNode: Sendable, Codable, Equatable {
    public let label: String
}

public struct PharoGraphEdge: Sendable, Codable, Equatable {
    public let from: Int
    public let to: Int
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
    case imageFailed(String, position: Int? = nil)
    case bridgeUnavailable
    case interrupted

    /// Where in the evaluated source a compile error sits, 1-based, when the
    /// image knew; nothing for a runtime error, which has no source spot.
    public var sourcePosition: Int? {
        if case .imageFailed(_, let position) = self { return position }
        return nil
    }
}

extension PharoRequestError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .imageFailed(let message, _):
            message
        case .bridgeUnavailable:
            "The image stopped answering"
        case .interrupted:
            "The request was interrupted"
        }
    }
}

struct PharoFailure: Decodable {
    let error: String
    let message: String?
    let position: Int?

    var description: String {
        guard let message, !message.isEmpty else { return error }
        return message
    }
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
    public let examples: [PharoExampleMethod]
}

/// A method that hands back something worth looking at -- a sample instance or a
/// worked example -- which a browser can run with one click.
public struct PharoExampleMethod: Sendable, Decodable, Identifiable {
    public let selector: String
    public let side: String

    public var id: String { "\(side)>>\(selector)" }
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
