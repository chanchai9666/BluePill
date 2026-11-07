import XCTest
@testable import BluePill

final class PowerAssertionManagerTests: XCTestCase {
    func testInitialStateIsNotAsserting() {
        let manager = PowerAssertionManager()
        XCTAssertFalse(manager.isAsserting)
    }

    func testActivateAndDeactivateTransitions() {
        let manager = PowerAssertionManager()
        let success = manager.activate()
        XCTAssertTrue(success)
        XCTAssertTrue(manager.isAsserting)

        manager.deactivate()
        XCTAssertFalse(manager.isAsserting)
    }

    func testDoubleActivateDoesNotDuplicate() {
        let manager = PowerAssertionManager()
        XCTAssertTrue(manager.activate())
        XCTAssertTrue(manager.activate()) // Should be idempotent
        XCTAssertTrue(manager.isAsserting)
        manager.deactivate()
        XCTAssertFalse(manager.isAsserting)
    }
}
