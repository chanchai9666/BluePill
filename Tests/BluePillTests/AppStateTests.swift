import XCTest
@testable import BluePill

final class MockPowerManager: PowerAssertionManaging {
    var isAsserting: Bool = false
    var activateCalled = 0
    var deactivateCalled = 0

    func activate() -> Bool {
        activateCalled += 1
        isAsserting = true
        return true
    }

    func deactivate() {
        deactivateCalled += 1
        isAsserting = false
    }
}

@MainActor
final class AppStateTests: XCTestCase {
    func testTimeFormatting() {
        let mock = MockPowerManager()
        let state = AppState(powerManager: mock)
        state.elapsedSeconds = 0
        XCTAssertEqual(state.formattedElapsedTime, "00:00:00")
        state.elapsedSeconds = 65
        XCTAssertEqual(state.formattedElapsedTime, "00:01:05")
        state.elapsedSeconds = 3661
        XCTAssertEqual(state.formattedElapsedTime, "01:01:01")
    }

    func testStartActivatesAndResetsTimer() {
        let mock = MockPowerManager()
        let state = AppState(powerManager: mock)
        state.elapsedSeconds = 120 // previous run
        state.start()

        XCTAssertTrue(state.isActive)
        XCTAssertEqual(state.elapsedSeconds, 0)
        XCTAssertEqual(mock.activateCalled, 1)
        XCTAssertEqual(state.menuBarTitle, " 00:00:00")
    }

    func testStopFreezesTimerValue() {
        let mock = MockPowerManager()
        let state = AppState(powerManager: mock)
        state.start()
        state.elapsedSeconds = 42
        state.stop()

        XCTAssertFalse(state.isActive)
        XCTAssertEqual(state.elapsedSeconds, 42) // Freezes at 42
        XCTAssertEqual(mock.deactivateCalled, 1)
        XCTAssertEqual(state.menuBarTitle, "")
    }

    func testRestartResetsTimerBackToZero() {
        let mock = MockPowerManager()
        let state = AppState(powerManager: mock)
        state.start()
        state.elapsedSeconds = 50
        state.stop()
        XCTAssertEqual(state.elapsedSeconds, 50)

        state.start()
        XCTAssertEqual(state.elapsedSeconds, 0) // Resets to 0 on new start
    }

    func testRapidStartStopToggling() {
        let mock = MockPowerManager()
        let state = AppState(powerManager: mock)
        for _ in 0..<10 {
            state.start()
            state.stop()
        }
        XCTAssertFalse(state.isActive)
        XCTAssertEqual(mock.activateCalled, 10)
        XCTAssertEqual(mock.deactivateCalled, 10)
        XCTAssertFalse(mock.isAsserting)
    }

    func testAnchorTimeBasedCalculation() {
        let mock = MockPowerManager()
        let state = AppState(powerManager: mock)
        // Verify state has startTime property anchored on start
        state.start()
        XCTAssertNotNil(state.startTime)
        state.stop()
    }
}
