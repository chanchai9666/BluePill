import Foundation
import IOKit.pwr_mgt

public protocol PowerAssertionManaging: AnyObject {
    var isAsserting: Bool { get }
    func activate() -> Bool
    func deactivate()
}

public final class PowerAssertionManager: PowerAssertionManaging {
    private var assertionIDs: [IOPMAssertionID] = []

    public private(set) var isAsserting: Bool = false

    public init() {}

    deinit {
        deactivate()
    }

    @discardableResult
    public func activate() -> Bool {
        if isAsserting {
            return true
        }

        let reason = "BluePill keep-awake active (caffeinate -dis)" as CFString
        var displayAssertionID: IOPMAssertionID = 0
        var idleAssertionID: IOPMAssertionID = 0
        var systemAssertionID: IOPMAssertionID = 0

        // 1. Prevent display idle sleep (-d)
        let displayResult = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &displayAssertionID
        )

        // 2. Prevent system idle sleep (-i)
        let idleResult = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &idleAssertionID
        )

        // 3. Prevent system sleep (-s)
        let systemResult = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &systemAssertionID
        )

        if displayResult == kIOReturnSuccess {
            assertionIDs.append(displayAssertionID)
        }
        if idleResult == kIOReturnSuccess {
            assertionIDs.append(idleAssertionID)
        }
        if systemResult == kIOReturnSuccess {
            assertionIDs.append(systemAssertionID)
        }

        isAsserting = !assertionIDs.isEmpty
        return isAsserting
    }

    public func deactivate() {
        guard isAsserting else { return }

        for id in assertionIDs {
            IOPMAssertionRelease(id)
        }
        assertionIDs.removeAll()
        isAsserting = false
    }
}
