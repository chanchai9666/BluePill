import AppKit
import SwiftUI
import Combine

public final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()
    private var lastCloseTime: Date = .distantPast

    @MainActor
    public let appState = AppState()

    public func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        observeAppState()
    }

    public func applicationWillTerminate(_ notification: Notification) {
        Task { @MainActor in
            appState.cleanup()
        }
        stopEventMonitor()
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.imagePosition = .imageLeft
            button.action = #selector(togglePopover(_:))
            button.target = self
            Task { @MainActor in
                self.updateStatusItem()
            }
        }
        self.statusItem = item
    }

    private func setupPopover() {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 290, height: 260)
        popover.behavior = .transient
        popover.animates = false // Prevents animation repositioning glitches
        popover.delegate = self
        popover.contentViewController = NSHostingController(
            rootView: PopoverView(appState: appState, onQuit: {
                NSApp.terminate(nil)
            })
        )
        self.popover = popover
    }

    private func observeAppState() {
        Task { @MainActor in
            appState.objectWillChange
                .receive(on: RunLoop.main)
                .sink { [weak self] _ in
                    self?.updateStatusItem()
                }
                .store(in: &self.cancellables)
        }
    }

    @MainActor
    private func updateStatusItem() {
        guard let button = statusItem?.button else { return }
        button.image = PillAsset.menuBarIcon(isActive: appState.isActive)

        // If popover is currently shown, do NOT resize/change button.title
        // because changing the button frame while NSPopover is anchored to it
        // causes AppKit to teleport the popover to (0,0) top-left!
        if let popover = popover, popover.isShown {
            return
        }

        button.title = appState.isActive ? " \(appState.formattedElapsedTime)" : ""
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
        Task { @MainActor in
            self.updateStatusItem()
        }
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
