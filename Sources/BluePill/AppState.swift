import Foundation
import Combine

@MainActor
public final class AppState: ObservableObject {
    @Published public var isActive: Bool = false
    @Published public var elapsedSeconds: Int = 0

    public private(set) var startTime: Date?

    private let powerManager: PowerAssertionManaging
    private var timer: Timer?

    public init(powerManager: PowerAssertionManaging = PowerAssertionManager()) {
        self.powerManager = powerManager
    }

    public var formattedElapsedTime: String {
        let hours = elapsedSeconds / 3600
        let minutes = (elapsedSeconds % 3600) / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    public var menuBarTitle: String {
        if isActive {
            return "💊 \(formattedElapsedTime)"
        } else {
            return "💊"
        }
    }

    public func toggleState() {
        if isActive {
            stop()
        } else {
            start()
        }
    }

    public func start() {
        guard !isActive else { return }

        elapsedSeconds = 0
        let success = powerManager.activate()
        guard success else { return }

        let now = Date()
        self.startTime = now
        isActive = true
        startTimer(from: now)
    }

    public func stop() {
        guard isActive else { return }

        stopTimer()
        if let start = startTime {
            let calculated = Int(Date().timeIntervalSince(start))
            elapsedSeconds = max(elapsedSeconds, calculated)
        }
        startTime = nil
        powerManager.deactivate()
        isActive = false
    }

    public func reset() {
        elapsedSeconds = 0
        startTime = nil
    }

    public func cleanup() {
        stop()
    }

    private func startTimer(from start: Date) {
        stopTimer()
        let newTimer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                guard self.isActive, let start = self.startTime else { return }
                self.elapsedSeconds = max(0, Int(Date().timeIntervalSince(start)))
            }
        }
        RunLoop.main.add(newTimer, forMode: .common)
        self.timer = newTimer
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
