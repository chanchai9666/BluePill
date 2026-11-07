import XCTest
@testable import BluePill

final class PowerAssertionIntegrationTests: XCTestCase {
    func testSystemAssertionRegistration() throws {
        let testReason = "BluePill-Test-\(ProcessInfo.processInfo.processIdentifier)"
        let manager = PowerAssertionManager(reason: testReason)
        XCTAssertTrue(manager.activate())

        // Run pmset -g assertions and verify our assertion name appears
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g", "assertions"]

        let pipe = Pipe()
        process.standardOutput = pipe
        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        XCTAssertTrue(
            output.contains(testReason),
            "pmset assertions should include BluePill assertion: \(output)"
        )

        manager.deactivate()

        let verifyProcess = Process()
        verifyProcess.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        verifyProcess.arguments = ["-g", "assertions"]
        let verifyPipe = Pipe()
        verifyProcess.standardOutput = verifyPipe
        try verifyProcess.run()
        verifyProcess.waitUntilExit()

        let verifyData = verifyPipe.fileHandleForReading.readDataToEndOfFile()
        let verifyOutput = String(data: verifyData, encoding: .utf8) ?? ""

        XCTAssertFalse(
            verifyOutput.contains(testReason),
            "pmset assertions should not contain BluePill test reason after deactivation"
        )
    }
}
