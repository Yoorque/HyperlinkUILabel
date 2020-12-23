import XCTest
@testable import HyperlinkUILabel

@available(iOS 10.0, *)
final class HyperlinkUILabelTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(HyperlinkUILabel().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
