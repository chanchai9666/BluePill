# BluePill: macOS Menu Bar Caffeinate App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a lightweight, native macOS menu bar utility (`BluePill.app`) for Apple Silicon Mac M1 that acts like `caffeinate -dis` with a toggle switch, live elapsed timer, MacBook charger warning banner, and automatic timer reset.

**Architecture:** A native AppKit accessory app (`LSUIElement = true`) hosting a status item on `NSStatusBar` with an `NSPopover` containing a SwiftUI card view. A `PowerAssertionManager` manages native IOKit power assertions (`IOPMAssertionCreateWithName`), and an `AppState` observable object drives the reactive UI, timer ticking, and state lifecycle.

**Tech Stack:** Swift 6 / Swift 5.9, AppKit (`NSStatusBar`, `NSStatusItem`, `NSPopover`), SwiftUI, IOKit (`IOPMLib`), Swift Package Manager, bash packaging script.

**Spec:** `docs/superpowers/specs/2026-11-07-bluepill-menubar-app-design.md`

## Global Constraints
- Target platform: macOS 13.0+ on Apple Silicon (`arm64`), compatible with Mac M1.
- No dock icon: `LSUIElement` must be `true` in `Info.plist`.
- Menu bar icon: Pill emoji/glyph 💊 with dynamic timer string when active (`💊 00:00:00`).
- Exact sleep assertion behavior: Must prevent display sleep (`kIOPMAssertionTypePreventUserIdleDisplaySleep`) and system idle sleep (`kIOPMAssertionTypePreventUserIdleSystemSleep`), matching `caffeinate -dis`.
- Exact timer behavior: Reset to 0 and count up on ON, freeze at current duration on OFF, reset to 0 on subsequent ON.
- Exact copy for MacBook warning banner: "คำแนะนำสำหรับ MacBook: กรุณาเสียบสายชาร์จขณะเปิดใช้งานเพื่อให้ระบบทำงานได้อย่างต่อเนื่อง"
- Zero orphaned assertions: All assertions must be released immediately when toggled OFF and upon `applicationWillTerminate`.

## Review Focus
1. **App Termination Cleanup:** If the user quits the app while active, all IOKit power assertions must be released cleanly so the Mac can sleep normally.
2. **Timer Freeze Precision:** Toggling OFF must immediately stop the timer and preserve the exact second count without drifting or jumping back to 0 until toggled ON again.
3. **Repeated Rapid Toggling:** Rapidly toggling ON and OFF multiple times must never leak assertion IDs or cause multiple concurrent timers to run.
4. **Popover Outside Click:** Clicking outside the popover card should dismiss it naturally, matching standard macOS menu bar popover behavior.
5. **No Dock or Window Leak:** App must run strictly in the menu bar with no visible Dock icon and no main window on launch.

---

### Task 1: Swift Package Scaffolding & PowerAssertionManager

**Files:**
- Create: `Package.swift`
- Create: `Sources/BluePill/PowerAssertionManager.swift`
- Test: `Tests/BluePillTests/PowerAssertionManagerTests.swift`

**Interfaces:**
- Produces:
  ```swift
  public protocol PowerAssertionManaging {
      var isAsserting: Bool { get }
      func activate() -> Bool
      func deactivate()
  }
  public final class PowerAssertionManager: PowerAssertionManaging {
      public init()
      public private(set) var isAsserting: Bool
      public func activate() -> Bool
      public func deactivate()
  }
  ```

- [ ] **Step 1: Create Package.swift**

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BluePill",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "BluePill", targets: ["BluePill"])
    ],
    targets: [
        .executableTarget(
            name: "BluePill",
            path: "Sources/BluePill"
        ),
        .testTarget(
            name: "BluePillTests",
            dependencies: ["BluePill"],
            path: "Tests/BluePillTests"
        )
    ]
)
```

- [ ] **Step 2: Write failing test for PowerAssertionManager**

```swift
// Tests/BluePillTests/PowerAssertionManagerTests.swift
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
```

- [ ] **Step 3: Run test to verify it fails**

Run: `swift test --filter PowerAssertionManagerTests`
Expected: FAIL with "cannot find 'PowerAssertionManager' in scope"

- [ ] **Step 4: Implement PowerAssertionManager**

Implement `PowerAssertionManager` in `Sources/BluePill/PowerAssertionManager.swift` using `IOKit.pwr_mgt.IOPMAssertionCreateWithName` with assertions:
- `kIOPMAssertionTypePreventUserIdleDisplaySleep`
- `kIOPMAssertionTypePreventUserIdleSystemSleep`
Cleanly storing assertion IDs and calling `IOPMAssertionRelease` in `deactivate()` and `deinit`.

- [ ] **Step 5: Run tests and verify they pass**

Run: `swift test --filter PowerAssertionManagerTests`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add Package.swift Sources/BluePill/PowerAssertionManager.swift Tests/BluePillTests/PowerAssertionManagerTests.swift
git commit -m "feat: add PowerAssertionManager with IOKit sleep prevention assertions"
```

---

### Task 2: AppState & Timer Engine

**Files:**
- Create: `Sources/BluePill/AppState.swift`
- Test: `Tests/BluePillTests/AppStateTests.swift`

**Interfaces:**
- Consumes: `PowerAssertionManaging` from Task 1
- Produces:
  ```swift
  public final class AppState: ObservableObject {
      @Published public var isActive: Bool
      @Published public var elapsedSeconds: Int
      public var formattedElapsedTime: String { get }
      public var menuBarTitle: String { get }
      public init(powerManager: PowerAssertionManaging = PowerAssertionManager())
      public func toggleState()
      public func start()
      public func stop()
      public func reset()
      public func cleanup()
  }
  ```

- [ ] **Step 1: Write failing test for AppState**

```swift
// Tests/BluePillTests/AppStateTests.swift
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
        XCTAssertEqual(state.menuBarTitle, "💊 00:00:00")
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
        XCTAssertEqual(state.menuBarTitle, "💊")
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
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter AppStateTests`
Expected: FAIL with "cannot find 'AppState' in scope"

- [ ] **Step 3: Implement AppState in Sources/BluePill/AppState.swift**

Implement `AppState` with:
- Timer ticking mechanism using `Timer.scheduledTimer` (or `DispatchSourceTimer`) on main runloop.
- `formattedElapsedTime`: String format `%02d:%02d:%02d` for hours, minutes, seconds.
- `menuBarTitle`: `"💊 \(formattedElapsedTime)"` when active, `"💊"` when inactive.
- `cleanup()`: calls `stop()`, releases assertions.

- [ ] **Step 4: Run tests and verify they pass**

Run: `swift test --filter AppStateTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Sources/BluePill/AppState.swift Tests/BluePillTests/AppStateTests.swift
git commit -m "feat: add AppState with timer lifecycle, freeze on stop, and reset on start"
```

---

### Task 3: SwiftUI Popover View with MacBook Charger Warning

**Files:**
- Create: `Sources/BluePill/PopoverView.swift`

**Interfaces:**
- Consumes: `AppState` from Task 2
- Produces:
  ```swift
  public struct PopoverView: View {
      @ObservedObject public var appState: AppState
      public var onQuit: () -> Void
      public init(appState: AppState, onQuit: @escaping () -> Void)
  }
  ```

- [ ] **Step 1: Implement PopoverView in Sources/BluePill/PopoverView.swift**

Create SwiftUI view adhering to the approved spec:
- Header: 💊 badge icon + "BluePill" + Status badge (`● Active (caffeinate -dis)` in green or `○ Inactive (Normal sleep)` in gray).
- Large Toggle switch bound to `appState.isActive` (with `.onChange(of: appState.isActive)` to trigger `start()` or `stop()`).
- Monospaced digital clock card displaying `appState.formattedElapsedTime` with title "Awake Duration" (when active) or "Stopped at" (when inactive).
- MacBook warning callout:
  - Yellow/amber tinted box with ⚡️ icon.
  - Text: `"คำแนะนำสำหรับ MacBook: กรุณาเสียบสายชาร์จขณะเปิดใช้งานเพื่อให้ระบบทำงานได้อย่างต่อเนื่อง"`.
- Footer: Description text + Quit button calling `onQuit`.

- [ ] **Step 2: Build executable target to verify SwiftUI compilation**

Run: `swift build`
Expected: Build succeeds with 0 errors.

- [ ] **Step 3: Commit**

```bash
git add Sources/BluePill/PopoverView.swift
git commit -m "feat: add SwiftUI PopoverView with toggle, timer display, and MacBook charger warning"
```

---

### Task 4: AppKit Menu Bar Resident Controller & Lifecycle

**Files:**
- Create: `Sources/BluePill/AppDelegate.swift`
- Create: `Sources/BluePill/main.swift`

**Interfaces:**
- Consumes: `AppState`, `PopoverView`
- Produces:
  - Standalone macOS Menu Bar application entry point.

- [ ] **Step 1: Implement AppDelegate in Sources/BluePill/AppDelegate.swift**

Implement `NSApplicationDelegate`:
- Creates `NSStatusItem` in `NSStatusBar.system`.
- Sets up `NSPopover` hosting `PopoverView(appState: appState, onQuit: { NSApp.terminate(nil) })`.
- Subscribes to `appState.$menuBarTitle` to update `statusItem.button?.title` in real-time.
- Implements outside click event monitor (`NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown])`) to auto-close popover when clicking elsewhere.
- Implements `applicationWillTerminate(_:)` to call `appState.cleanup()` ensuring zero assertion leaks.

- [ ] **Step 2: Implement main.swift in Sources/BluePill/main.swift**

```swift
import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory) // Hides from Dock, runs strictly in menu bar
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
```

- [ ] **Step 3: Build to verify compilation**

Run: `swift build`
Expected: Build complete! `[X/X] Linking BluePill`

- [ ] **Step 4: Commit**

```bash
git add Sources/BluePill/AppDelegate.swift Sources/BluePill/main.swift
git commit -m "feat: implement AppKit menu bar status item and application lifecycle"
```

---

### Task 5: Packaging BluePill.app Bundle & Verification

**Files:**
- Create: `scripts/build-app.sh`
- Create: `Resources/Info.plist`

- [ ] **Step 1: Create Resources/Info.plist**

Define `Info.plist` with:
- `CFBundleExecutable`: `BluePill`
- `CFBundleIdentifier`: `com.bluepill.caffeinate`
- `CFBundleName`: `BluePill`
- `CFBundlePackageType`: `APPL`
- `CFBundleShortVersionString`: `1.0.0`
- `LSUIElement`: `true` (Accessory app, hidden from Dock)
- `LSMinimumSystemVersion`: `13.0`

- [ ] **Step 2: Create scripts/build-app.sh**

Write packaging script that:
1. Runs `swift build -c release --arch arm64`.
2. Creates `BluePill.app/Contents/MacOS` and `BluePill.app/Contents/Resources`.
3. Copies release binary to `BluePill.app/Contents/MacOS/BluePill`.
4. Copies `Info.plist` to `BluePill.app/Contents/Info.plist`.
5. Code-signs ad-hoc with `codesign --force --deep --sign - BluePill.app`.

- [ ] **Step 3: Run build-app.sh and verify bundle structure**

Run: `bash scripts/build-app.sh`
Expected: `BluePill.app` created and successfully signed.

- [ ] **Step 4: Verify sleep assertion using `pmset -g assertions`**

1. Launch `BluePill.app` in background.
2. Verify process is running: `pgrep -x BluePill`.
3. Verify assertion is active when turned on: `pmset -g assertions | grep PreventUserIdleDisplaySleep`.
4. Terminate app and verify assertions return to normal.

- [ ] **Step 5: Commit**

```bash
git add scripts/build-app.sh Resources/Info.plist
git commit -m "feat: add app bundle packaging script and Info.plist"
```
