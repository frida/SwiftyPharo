import XCTest

@testable import SwiftyPharo

final class PharoRuntimeTests: XCTestCase {
    func testRuntimeStartsBeforeAnyBoot() throws {
        try XCTSkipIf(bootedImage != nil, "another test booted the VM")

        XCTAssertEqual(PharoRuntime.shared.state, .starting)
    }

    /// Point SWIFTY_PHARO_IMAGE at a built image to exercise the whole channel;
    /// a process hosts one VM, so this runs alone.
    func testWalksTheViewsAnObjectDeclares() async throws {
        let image = try XCTUnwrap(bootedImage, "set SWIFTY_PHARO_IMAGE to run this")

        let runtime = PharoRuntime.shared
        runtime.boot(image: URL(fileURLWithPath: image))
        try await runtime.runningState()

        let probe = try await runtime.evaluate("SwpProbe new")
        XCTAssertEqual(probe.className, "SwpProbe")

        let views = try await runtime.views(of: probe)
        XCTAssertEqual(views.prefix(2).map(\.viewName), ["list", "text"])
        XCTAssertEqual(views.first?.title, "Numbers")
        XCTAssertEqual(
            views.first { $0.title == "Raw" }?.columns,
            [PharoColumn(title: "Index"), PharoColumn(title: "Variable", width: .fitContent), PharoColumn(title: "Value")])

        let page = try await runtime.items(of: probe, view: "gtNumbersFor:", from: 2, count: 2)
        XCTAssertEqual(page.total, 5)
        XCTAssertEqual(page.items.map { $0.map(\.description) }, [["2", "n=2"], ["3", "n=3"]])

        let element = try await runtime.drillInto(probe, view: "gtNumbersFor:", index: 3)
        XCTAssertEqual(element.printString, "3")
        XCTAssertNotEqual(element.handle, probe.handle)

        try await runtime.release(element)
    }

    private var bootedImage: String? {
        ProcessInfo.processInfo.environment["SWIFTY_PHARO_IMAGE"]
    }
}
