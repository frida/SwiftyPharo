import Foundation
import SwiftyPharo

/// Walks the views an object declares, to check an embedded image end to end.
@available(macOS 12, iOS 15, *)
@main
struct Probe {
    static func main() async throws {
        setbuf(stdout, nil)

        let arguments = CommandLine.arguments
        guard arguments.count == 3 else {
            print("usage: swifty-pharo-probe <image> <plugins>")
            exit(1)
        }

        let runtime = PharoRuntime.shared
        runtime.boot(
            image: URL(fileURLWithPath: arguments[1]),
            plugins: URL(fileURLWithPath: arguments[2]))

        try await runtime.runningState()
        print("state: \(runtime.state)")

        let probe = try await runtime.evaluate("SwpProbe new")
        print("evaluated: \(probe.className) \(probe.printString) handle=\(probe.handle)")

        for view in try await runtime.views(of: probe) {
            print("view: \(view.viewName) \"\(view.title)\" priority=\(view.priority) <- \(view.methodSelector)")
        }

        let page = try await runtime.items(of: probe, view: "gtNumbersFor:", from: 2, count: 2)
        print("items: total=\(page.total) window=\(page.items)")

        let element = try await runtime.drillInto(probe, view: "gtNumbersFor:", index: 3)
        print("drilled: handle=\(element.handle) \(element.printString)")

        try await runtime.release(element)
        print("released")
        exit(0)
    }
}
