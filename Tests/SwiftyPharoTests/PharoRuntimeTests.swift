import XCTest

@testable import SwiftyPharo

final class PharoRuntimeTests: XCTestCase {
    func testRuntimeStartsBeforeAnyBoot() {
        XCTAssertEqual(PharoRuntime.shared.state, .starting)
    }
}
