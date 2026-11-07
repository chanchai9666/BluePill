import SwiftUI

public struct PopoverView: View {
    @ObservedObject public var appState: AppState
    public var onQuit: () -> Void

    public init(appState: AppState, onQuit: @escaping () -> Void) {
        self.appState = appState
        self.onQuit = onQuit
    }

    public var body: some View {
        VStack(spacing: 14) {
            // Header Row: Icon, App Name, Status & Toggle
            HStack(alignment: .center, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(appState.isActive ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 32, height: 32)
                    Text("💊")
                        .font(.system(size: 16))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("BluePill")
                        .font(.system(size: 14, weight: .semibold))
                    Text(appState.isActive ? "● Active (caffeinate -dis)" : "○ Inactive (Normal sleep)")
                        .font(.system(size: 10))
                        .foregroundColor(appState.isActive ? .green : .secondary)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { appState.isActive },
                    set: { newValue in
                        if newValue {
                            appState.start()
                        } else {
                            appState.stop()
                        }
                    }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
            }

            // Timer Digital Display Box
            VStack(spacing: 4) {
                Text(appState.isActive ? "Awake Duration" : "Stopped at")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)

                Text(appState.formattedElapsedTime)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(appState.isActive ? .cyan : .secondary)
                    .tracking(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.primary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )

            // MacBook Charger Warning Callout
            HStack(alignment: .top, spacing: 8) {
                Text("⚡️")
                    .font(.system(size: 13))

                Text("คำแนะนำสำหรับ MacBook: กรุณาเสียบสายชาร์จขณะเปิดใช้งานเพื่อให้ระบบทำงานได้อย่างต่อเนื่อง")
                    .font(.system(size: 10.5))
                    .foregroundColor(.orange)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.orange.opacity(0.35), lineWidth: 1)
            )

            Divider()

            // Footer: Subtitle & Quit Button
            HStack {
                Text(appState.isActive ? "Mac will stay awake" : "Normal sleep mode")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: onQuit) {
                    Text("Quit (⌘Q)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("q", modifiers: .command)
            }
        }
        .padding(16)
        .frame(width: 290, height: 260)
    }
}
