import SwiftUI

/// "Stay online": what it does, whether it's working, a way to test it, and
/// the macOS settings that decide which network the Mac rejoins.
struct ConnectionSettings: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var connection = model.connection
        VStack(alignment: .leading, spacing: 0) {
            header(isOn: $connection.isEnabled)
                .padding(.horizontal, 22)
                .padding(.top, 20)
                .padding(.bottom, 16)

            HStack(spacing: 10) {
                StatusLine(connection: connection)
                Spacer()
                Button { connection.testNow() } label: {
                    Label("Test now", systemImage: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(connection.isRecovering || model.helperStatus != .ready)
            }
            .padding(.horizontal, 22)

            Group {
                if let recovery = connection.lastRecovery {
                    let time = recovery.date.formatted(date: .omitted, time: .shortened)
                    Text("Last reconnected at \(time), back online in \(recovery.seconds) s")
                } else {
                    Text("Wi-Fi turns off for a few seconds, then your Mac rejoins the best saved network.")
                }
            }
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 22)
            .padding(.top, 8)

            if model.helperStatus != .ready {
                Label("Needs the helper. Set it up from the menu bar.", systemImage: "lock.shield")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.ember)
                    .padding(.horizontal, 22)
                    .padding(.top, 10)
            }

            Divider().padding(.horizontal, 22).padding(.vertical, 18)

            HotspotTips()
                .padding(.horizontal, 22)
                .padding(.bottom, 22)
        }
        .frame(width: 460)
        .background(alignment: .top) {
            RadialGradient(
                colors: [Color.blue.opacity(connection.isEnabled ? 0.16 : 0.06), .clear],
                center: UnitPoint(x: 0.15, y: 0), startRadius: 0, endRadius: 320
            )
            .frame(height: 260)
            .allowsHitTesting(false)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: connection.isEnabled)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: connection.status)
    }

    private func header(isOn: Binding<Bool>) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "wifi")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LinearGradient(colors: [Color(red: 0.36, green: 0.55, blue: 1.0), Color(red: 0.22, green: 0.33, blue: 0.86)],
                                             startPoint: .top, endPoint: .bottom))
                )
                .shadow(color: .blue.opacity(0.3), radius: 8, y: 3)
            VStack(alignment: .leading, spacing: 4) {
                Text("Stay online")
                    .font(.system(size: 20, weight: .semibold, design: Theme.rounded))
                Text("If the internet drops for 20 seconds while Melatonin keeps your Mac awake, it restarts Wi-Fi so macOS rejoins a saved network in range, such as your phone’s hotspot.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .tint(Theme.ember)
                .labelsHidden()
        }
    }
}

/// The macOS and phone settings that decide whether the hotspot gets picked.
private struct HotspotTips: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Make sure your Mac picks your phone’s hotspot", systemImage: "personalhotspot")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)
            tip(1, "Join the hotspot once from the Wi-Fi menu so your Mac saves it.")
            tip(2, "In System Settings › Wi-Fi, open the hotspot’s Details and turn on “Automatically join this network”.")
            tip(3, "Android: turn off the setting that switches the hotspot off when no devices are connected.")
            tip(4, "Using an iPhone? macOS can join its Personal Hotspot automatically: Wi-Fi settings › Ask to join hotspots › Automatic.")
            Button("Open Wi-Fi Settings") {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.wifi-settings-extension")!)
            }
            .buttonStyle(.link)
            .font(.system(size: 11, weight: .medium))
            .padding(.leading, 26)
        }
    }

    private func tip(_ number: Int, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(verbatim: "\(number)")
                .font(.system(size: 10, weight: .bold, design: Theme.rounded))
                .foregroundStyle(.green)
                .frame(width: 18, height: 18)
                .background(Circle().fill(.green.opacity(0.14)))
            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct StatusLine: View {
    let connection: ConnectionGuard

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
                .shadow(color: color.opacity(0.8), radius: 3)
            Text(connection.summary)
                .font(.system(size: 12, weight: .medium, design: Theme.rounded))
                .contentTransition(.opacity)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(color.opacity(0.12)))
    }

    private var color: Color {
        switch connection.status {
        case .online: .green
        case .offline, .exhausted: .red
        case .restartingWiFi: Theme.amber
        case .off, .standby: .secondary
        }
    }
}
