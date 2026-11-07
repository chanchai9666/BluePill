import AppKit
import SwiftUI
import Combine

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()
    private var lastCloseTime: Date = .distantPast

    public let appState = AppState()

    public func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        observeAppState()
    }

    public func applicationWillTerminate(_ notification: Notification) {
        // Guaranteed synchronous release of sleep assertions before process exits
        appState.cleanup()
        stopEventMonitor()
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.statusItem = item
        if let button = item.button {
            button.imagePosition = .imageLeft
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
            button.action = #selector(togglePopover(_:))
            button.target = self
            self.updateStatusItem()
        }
    }

    private func setupPopover() {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 290, height: 260)
        popover.behavior = .transient
        popover.animates = false // Prevents animation repositioning glitches
        popover.delegate = self
        popover.contentViewController = NSHostingController(
            rootView: PopoverView(appState: appState, onQuit: { [weak self] in
                self?.appState.quit()
            })
        )
        self.popover = popover
    }

    private func observeAppState() {
        appState.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateStatusItem()
            }
            .store(in: &cancellables)
    }

    private func updateStatusItem() {
        guard let button = statusItem?.button else { return }
        button.image = PillAsset.menuBarIcon(isActive: appState.isActive)

        // If popover is currently shown, do NOT resize button.title to prevent AppKit
        // from re-anchoring and teleporting the popover to (0,0)
        if let popover = popover, popover.isShown {
            return
        }

        button.title = appState.menuBarTitle
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let popover = popover, let button = statusItem?.button else { return }

        if popover.isShown {
            closePopover(sender)
            return
        }

        // If the popover just closed milliseconds ago because user clicked on the status button,
        // do not reopen immediately.
        if Date().timeIntervalSince(lastCloseTime) < 0.25 {
            return
        }

        showPopover(button)
    }

    private func showPopover(_ button: NSStatusBarButton) {
        guard let popover = popover else { return }
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        startEventMonitor()
    }

    private func closePopover(_ sender: AnyObject?) {
        popover?.performClose(sender)
        stopEventMonitor()
    }

    // MARK: - NSPopoverDelegate
    public func popoverDidClose(_ notification: Notification) {
        lastCloseTime = Date()
        stopEventMonitor()
        self.updateStatusItem()
    }

    private func startEventMonitor() {
        guard eventMonitor == nil else { return }
        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            guard let self = self, let popover = self.popover, popover.isShown else { return }
            self.closePopover(nil)
        }
    }

    private func stopEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
