import AppKit
import SwiftUI
import Combine

public final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()

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
            Task { @MainActor in
                button.title = self.appState.menuBarTitle
            }
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        self.statusItem = item
    }

    private func setupPopover() {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 290, height: 260)
        popover.behavior = .transient
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
                    self?.updateStatusItemTitle()
                }
                .store(in: &self.cancellables)
        }
    }

    @MainActor
    private func updateStatusItemTitle() {
        guard let button = statusItem?.button else { return }
        button.title = appState.menuBarTitle
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let popover = popover, let button = statusItem?.button else { return }

        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(button)
        }
    }

    private func showPopover(_ button: NSStatusBarButton) {
        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        startEventMonitor()
    }

    private func closePopover(_ sender: AnyObject?) {
        popover?.performClose(sender)
        stopEventMonitor()
    }

    // MARK: - NSPopoverDelegate
    public func popoverDidClose(_ notification: Notification) {
        stopEventMonitor()
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
