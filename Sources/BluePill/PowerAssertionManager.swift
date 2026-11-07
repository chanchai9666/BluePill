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
        let assertionTypes: [CFString] = [
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString, // -d
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,  // -i
            kIOPMAssertionTypePreventSystemSleep as CFString          // -s
        ]

        for type in assertionTypes {
            var assertionID: IOPMAssertionID = 0
            let result = IOPMAssertionCreateWithName(
                type,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                reason,
                &assertionID
            )
            if result == kIOReturnSuccess {
                assertionIDs.append(assertionID)
            }
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
