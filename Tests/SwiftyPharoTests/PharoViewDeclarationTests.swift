import XCTest

@testable import SwiftyPharo

final class PharoViewDeclarationTests: XCTestCase {
    func testDecodesThePrioritiesTheImageSends() throws {
        let list = try decode("""
            {"views":[
            {"viewName":"text","priority":0.75,"title":"Three quarters","methodSelector":"gtThreeQuartersFor:","text":"three quarters"},
            {"viewName":"text","priority":1,"title":"One","methodSelector":"gtOneFor:","text":"one"},
            {"viewName":"text","priority":1.5,"title":"One and a half","methodSelector":"gtOneAndAHalfFor:","text":"one and a half"},
            {"viewName":"text","priority":2,"title":"Two","methodSelector":"gtTwoFor:","text":"two"},
            {"viewName":"text","priority":1.7976931348623157e308,"title":"Endless","methodSelector":"gtEndlessFor:","text":"endless"}
            ]}
            """)

        XCTAssertEqual(list.views.map(\.priority), [0.75, 1, 1.5, 2, .greatestFiniteMagnitude])
    }

    func testADeclarationThatCannotBeReadIsShownInItsPlace() throws {
        let list = try decode("""
            {"views":[
            {"viewName":"text","priority":1,"title":"One","methodSelector":"gtOneFor:","text":"one"},
            {"viewName":"text","priority":"high","title":"High","methodSelector":"gtHighFor:","text":"never shown"},
            {"viewName":"text","priority":2,"title":"Two","methodSelector":"gtTwoFor:","text":"two"}
            ]}
            """)

        XCTAssertEqual(list.views.map(\.methodSelector), ["gtOneFor:", "gtHighFor:", "gtTwoFor:"])
        XCTAssertEqual(list.views.map(\.text), [
            "one",
            "gtHighFor: declared a priority that cannot be shown: Expected to decode Double but found a string instead.",
            "two",
        ])
        XCTAssertEqual(list.views[1].viewName, "text")
        XCTAssertEqual(list.views[1].title, "High (Error)")
        XCTAssertEqual(list.views[1].priority, 75)
    }

    func testADeclarationMissingAPriorityNamesIt() throws {
        let list = try decode("""
            {"views":[{"viewName":"text","title":"Bare","methodSelector":"gtBareFor:","text":"bare"}]}
            """)

        XCTAssertEqual(list.views.first?.text, "gtBareFor: declared no priority")
        XCTAssertEqual(list.views.first?.title, "Bare (Error)")
    }

    func testDecodesHowEachColumnIsSized() throws {
        let list = try decode("""
            {"views":[{"viewName":"columnedList","priority":1,"title":"Disassembly","methodSelector":"gtDisassemblyFor:","columns":[
            {"title":"Index"},
            {"title":"Address","fitContent":true,"priority":1},
            {"title":"Instruction","weight":2,"minimumCharacters":16},
            {"title":"Bytes","fitContent":true,"priority":4.5},
            {"title":"Icon","width":36}
            ]}]}
            """)

        XCTAssertEqual(list.views.first?.columns, [
            PharoColumn(title: "Index"),
            PharoColumn(title: "Address", width: .fitContent, priority: 1),
            PharoColumn(title: "Instruction", width: .weight(2), minimumCharacters: 16),
            PharoColumn(title: "Bytes", width: .fitContent, priority: 4.5),
            PharoColumn(title: "Icon", width: .points(36)),
        ])
        XCTAssertEqual(list.views.first?.columns?.map(\.isDeclared), [false, true, true, true, true])
    }

    func testAColumnThatCannotBeSizedIsShownAsTheViewsError() throws {
        let list = try decode("""
            {"views":[{"viewName":"columnedList","priority":1,"title":"Wide","methodSelector":"gtWideFor:","columns":[
            {"title":"Index"},{"title":"Name","weight":"wide"}]}]}
            """)

        XCTAssertEqual(list.views.first?.title, "Wide (Error)")
        XCTAssertEqual(
            list.views.first?.text,
            "gtWideFor: declared a columns.Index 1.weight that cannot be shown: Expected to decode Double but found a string instead.")
    }

    private func decode(_ json: String) throws -> PharoViewList {
        try JSONDecoder().decode(PharoViewList.self, from: Data(json.utf8))
    }
}
