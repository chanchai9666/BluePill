import XCTest
@testable import BluePill

final class PillAssetTests: XCTestCase {
    func testPillImageGeneration() {
        let activeImg = PillAsset.createPillImage(size: 18, isActive: true)
        XCTAssertEqual(activeImg.size.width, 18)
        XCTAssertEqual(activeImg.size.height, 18)
        XCTAssertNotNil(activeImg.tiffRepresentation)

        let inactiveImg = PillAsset.createPillImage(size: 18, isActive: false)
        XCTAssertEqual(inactiveImg.size.width, 18)
        XCTAssertEqual(inactiveImg.size.height, 18)
        XCTAssertNotNil(inactiveImg.tiffRepresentation)
    }
}
