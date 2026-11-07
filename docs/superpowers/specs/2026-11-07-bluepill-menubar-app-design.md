# BluePill: macOS Menu Bar Caffeinate Application Design

## 1. Intent and Context
Users frequently need to keep their Mac and display awake (e.g., during long downloads, running data pipelines, presenting, or compiling projects) without navigating system settings or keeping an open Terminal window running `caffeinate -dis`.

**BluePill** is a lightweight, native macOS menu bar utility tailored for Apple Silicon (Mac M1 and newer) that provides an effortless one-click interface to keep the Mac awake, tracks the active duration with an elapsed timer, and cleanly manages system sleep states.

---

## 2. Goals, Non-Goals, and Anti-Goals

### Goals
- **Menu Bar Resident:** Runs cleanly in the macOS menu bar as an accessory app (`LSUIElement = true`), with no distracting dock icon.
- **Pill Branding:** Uses a clean pill icon (💊) representing "BluePill".
- **Modern Popover Card:**
  - Big, tactile Toggle Switch (ON / OFF).
  - Digital elapsed timer display (`HH:MM:SS` format).
  - Real-time status indicator (Active with `caffeinate -dis` vs Inactive Normal Sleep).
  - Prominent MacBook charger warning/recommendation box ("คำแนะนำสำหรับ MacBook: กรุณาเสียบสายชาร์จขณะเปิดใช้งานเพื่อให้ระบบทำงานได้อย่างต่อเนื่อง").
  - Quit button (⌘Q).
- **Core Caffeinate Behavior:**
  - **ON:** Activates power assertions equivalent to `caffeinate -dis` (preventing Display sleep, Idle sleep, and System sleep). Starts counting up from `00:00:00`.
  - **OFF:** Releases power assertions immediately. Freezes elapsed timer at the last recorded value.
  - **Re-enable:** Resets elapsed timer to `00:00:00` and starts counting up from 0.
- **Menu Bar Display:** Displays pill icon and live elapsed time when active (e.g., `💊 00:24:18`), and dim pill icon without timer when inactive.
- **Resource Efficiency:** Written natively in Swift / AppKit / SwiftUI. Binary size < 5 MB, memory footprint < 30 MB, near 0% idle CPU usage.

### Non-Goals
- Complex countdown schedulers (e.g. "sleep in 2 hours") — keep the initial version dead simple as requested.
- Electron or webview wrappers.

### Anti-Goals
- Leaving orphaned `caffeinate` child processes or leaked system power assertions if the app is closed, terminated, or crashes.
- High battery drain or CPU wakeups when idle.

---

## 3. Architecture & Implementation Choices

### 3.1 Platform & Tech Stack
- **Language:** Swift 5.9+ / Swift 6
- **Frameworks:** AppKit (`NSStatusBar`, `NSStatusItem`, `NSPopover`), SwiftUI (for clean, reactive Popover UI), `IOKit` / `IOPMLib` for power assertions.
- **Architecture Target:** `arm64` (Apple Silicon M1/M2/M3/M4) / Universal macOS binary.
- **Packaging:** Standalone `.app` bundle (`BluePill.app`) with `Info.plist` setting `LSUIElement = true`.

### 3.2 Sleep Prevention Engine
Instead of relying on fragile shell process execution (`Process.run("/usr/bin/caffeinate")`), BluePill utilizes the exact same native macOS system APIs that `caffeinate` itself uses under the hood:
1. `IOPMAssertionCreateWithName`:
   - `kIOPMAssertionTypePreventUserIdleDisplaySleep` (`-d`)
   - `kIOPMAssertionTypePreventUserIdleSystemSleep` (`-i`)
   - `kIOPMAssertionTypePreventSystemSleep` (`-s`)
2. Assertions are tracked by an `IOPMAssertionID`.
3. When toggled OFF or upon app termination (`applicationWillTerminate`), `IOPMAssertionRelease` is guaranteed to release all active assertions immediately.

*(Fallback or verification: Can also monitor/execute `caffeinate -dis` process if assertion privileges require, but native IOKit assertion is standard for Mac App Store & third-party sleep prevention utilities like Amphetamine/Caffeine).*

### 3.3 State Management
- `AppState` (ObservableObject):
  - `isActive: Bool` (defaults to false or configured start)
  - `elapsedSeconds: Int`
  - `formattedElapsedTime: String` (computes `HH:MM:SS`)
  - `startCaffeinate()`: creates IOKit assertion, resets `elapsedSeconds = 0`, starts 1-second timer.
  - `stopCaffeinate()`: releases IOKit assertion, cancels timer, retains `elapsedSeconds`.
  - `quit()`: ensures assertions released and calls `NSApp.terminate(nil)`.

### 3.4 UI Design & Components
- **Status Item:**
  - `NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)`
  - Title shows pill icon + time string when active.
  - Click opens `NSPopover`.
- **Popover Card View (SwiftUI):**
  - **Header:** Pill icon badge + "BluePill" title + Live status badge (`● Active` / `○ Inactive`).
  - **Switch:** `Toggle("", isOn: $appState.isActive).toggleStyle(SwitchToggleStyle(tint: .green))`
  - **Timer Box:** Large monospaced digital clock (`00:00:00`) with label ("Awake Duration" or "Stopped at").
  - **MacBook Notice Banner:** Warning callout with ⚡️ icon:
    > "คำแนะนำสำหรับ MacBook: กรุณาเสียบปลั๊กชาร์จไฟไว้ เพื่อให้ระบบทำงานต่อเนื่องโดยที่แบตเตอรี่ไม่หมดระหว่างใช้งาน"
  - **Footer:** Quit button (`Quit BluePill ⌘Q`).

---

## 4. Verification & Testing Strategy
1. **Compilation Test:** Build native binary with Swift compiler / SPM on Mac M1.
2. **Power Assertion Verification:** Run `pmset -g assertions` in Terminal while BluePill is ON to verify that `PreventUserIdleDisplaySleep` and `PreventUserIdleSystemSleep` are actively asserted by `BluePill`.
3. **Toggle OFF Verification:** Verify `pmset -g assertions` removes the assertions when toggled OFF, and timer stops.
4. **Reset Verification:** Toggle ON again, verify timer resets to `00:00:00` and starts counting up.
5. **App Bundle Packaging:** Verify `BluePill.app` launches cleanly from Finder / Applications folder.
