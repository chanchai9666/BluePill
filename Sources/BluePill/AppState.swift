import Foundation
import Combine

public final class AppState: ObservableObject {
    @Published public var isActive: Bool = false
    @Published public var elapsedSeconds: Int = 0

    private let powerManager: PowerAssertionManaging
    private var timer: Timer?

    public init(powerManager: PowerAssertionManaging = PowerAssertionManager()) {
        self.powerManager = powerManager
    }

    deinit {
        cleanup()
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

        isActive = true
        startTimer()
    }

    public func stop() {
        guard isActive else { return }

        stopTimer()
        powerManager.deactivate()
        isActive = false
    }

    public func reset() {
        elapsedSeconds = 0
    }

    public func cleanup() {
        stop()
    }

    private func startTimer() {
        stopTimer()
        let newTimer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isActive else { return }
            self.elapsedSeconds += 1
        }
        RunLoop.main.add(newTimer, forMode: .common)
        self.timer = newTimer
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
