import SwiftUI

/// The window that drops down from the menu bar icon.
struct MenuPanel: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 0) {
            header
            hero
            VStack(alignment: .leading, spacing: 7) {
                Text("Stay awake for")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 2)
                DurationPicker()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)

            if model.helperStatus.needsSetup || model.lastError != nil {
                SetupCard()
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            Divider().padding(.horizontal, 12)
            SettingsList().padding(.vertical, 6)
            Divider().padding(.horizontal, 12)
            footer
        }
        .frame(width: 312)
        .background(alignment: .top) { glow }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: model.isAwake)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: model.helperStatus)
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(model.isAwake ? AnyShapeStyle(Theme.amber) : AnyShapeStyle(.secondary))
            Text(verbatim: "Melatonin")
                .font(.system(size: 13, weight: .semibold, design: Theme.rounded))
            Spacer()
            Menu {
                Picker("Language", selection: Binding(get: { model.language }, set: { model.language = $0 })) {
                    Text("Same as macOS").tag("")
                    ForEach(AppLanguage.supported, id: \.code) { language in
                        Text(verbatim: language.name).tag(language.code)
                    }
                }
                Button("About Melatonin") {
                    NSWorkspace.shared.open(URL(string: "https://github.com/jugol/Melatonin")!)
                }
                if model.helperStatus != .missing {
                    Button("Uninstall helper…") { model.uninstallHelper() }
                }
                Divider()
                Button("Quit Melatonin") { NSApp.terminate(nil) }
                    .keyboardShortcut("q")
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var hero: some View {
        VStack(spacing: 0) {
            Button { model.toggle() } label: {
                LampOrb(isOn: model.isAwake, size: 92)
            }
            .buttonStyle(PressableStyle())
            .padding(.top, 18)
            .padding(.bottom, 16)

            Text(model.headline)
                .font(.system(size: 21, weight: .semibold, design: Theme.rounded))
                .contentTransition(.opacity)
            Text(model.detail)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)
                .padding(.top, 3)
                .padding(.horizontal, 20)

            if model.isAwake, model.manualOn, let until = model.manualUntil {
                CountdownText(until: until)
                    .font(.system(size: 12, weight: .semibold, design: Theme.rounded))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Theme.amber.opacity(0.85)))
                    .padding(.top, 8)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .padding(.bottom, 18)
    }

    private var glow: some View {
        RadialGradient(
            colors: [Theme.amber.opacity(0.30), Theme.ember.opacity(0.10), .clear],
            center: UnitPoint(x: 0.5, y: 0.2), startRadius: 10, endRadius: 210
        )
        .frame(height: 300)
        .opacity(model.isAwake ? 1 : 0)
        .allowsHitTesting(false)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            BatteryLabel(battery: model.battery)
            if model.thermal == .serious || model.thermal == .critical {
                Label("Running hot", systemImage: "thermometer.high")
                    .foregroundStyle(.orange)
            }
            Spacer()
            Button("Quit") { NSApp.terminate(nil) }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
        }
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

private struct SetupCard: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.ember)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 12, weight: .semibold))
                Text(message)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if model.helperStatus != .installing, model.helperStatus != .ready {
                    Button { model.setUpHelper() } label: {
                        Text(buttonTitle)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Theme.amber))
                    }
                    .buttonStyle(PressableStyle())
                    .padding(.top, 4)
                } else if model.helperStatus == .installing {
                    ProgressView().controlSize(.small).padding(.top, 2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.amber.opacity(0.12))
                .strokeBorder(Theme.amber.opacity(0.35), lineWidth: 0.5)
        )
    }

    private var icon: String {
        switch model.helperStatus {
        case .failed, .unreachable: "exclamationmark.triangle.fill"
        default: model.lastError == nil ? "lock.shield.fill" : "exclamationmark.triangle.fill"
        }
    }

    private var title: LocalizedStringKey {
        switch model.helperStatus {
        case .unreachable: "Helper isn’t responding"
        case .outdated: "Helper update needed"
        case .failed: "Setup didn’t finish"
        case .ready: "Couldn’t switch"
        default: "One-time setup"
        }
    }

    private var message: String {
        switch model.helperStatus {
        case .unreachable:
            String(localized: "Check System Settings › General › Login Items, or reinstall the helper.")
        case .failed(let reason):
            reason
        case .ready:
            model.lastError ?? ""
        default:
            String(localized: "Staying awake with the lid closed needs a tiny helper. You’ll enter your password once.")
        }
    }

    private var buttonTitle: LocalizedStringKey {
        switch model.helperStatus {
        case .missing: "Set up"
        case .outdated: "Update"
        default: "Reinstall"
        }
    }
}

private struct SettingsList: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        @Bindable var model = model
        @Bindable var connection = model.connection
        VStack(spacing: 0) {
            SettingRow(symbol: "sparkles", tint: .purple, title: "Auto for AI agents", subtitle: agentSummary) {
                Toggle("", isOn: $model.autoForAgents)
            }
            SettingRow(symbol: "wifi", tint: .blue, title: "Stay online", subtitle: connection.summary) {
                HStack(spacing: 8) {
                    Button {
                        openWindow(id: ConnectionSettings.windowID)
                        NSApp.activate()
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .help("Choose networks")
                    Toggle("", isOn: $connection.isEnabled)
                }
            }
            SettingRow(symbol: "battery.25percent", tint: .green, title: "Stop at low battery") {
                Picker("", selection: $model.batteryFloor) {
                    Text("Off").tag(0)
                    ForEach([10, 20, 30, 50], id: \.self) { Text(verbatim: "\($0)%").tag($0) }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .fixedSize()
            }
            SettingRow(symbol: "thermometer.medium", tint: .orange, title: "Stop if it gets hot") {
                Toggle("", isOn: $model.stopWhenHot)
            }
            SettingRow(symbol: "capsule.fill", tint: .indigo, title: "Show in notch") {
                Toggle("", isOn: $model.showInNotch)
            }
            SettingRow(symbol: "power", tint: .gray, title: "Open at login") {
                Toggle("", isOn: $model.opensAtLogin)
            }
        }
        .toggleStyle(.switch)
        .controlSize(.mini)
        .tint(Theme.ember)
    }

    private var agentSummary: String {
        if let agent = model.agents.first(where: \.isWorking) ?? model.agents.first {
            return agent.isWorking
                ? String(localized: "\(agent.name) working")
                : String(localized: "\(agent.name) idle")
        }
        return String(localized: "Stays awake while Claude Code or Codex works")
    }
}

private struct SettingRow<Accessory: View>: View {
    let symbol: String
    let tint: Color
    let title: LocalizedStringKey
    var subtitle: String?
    @ViewBuilder var accessory: Accessory

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(RoundedRectangle(cornerRadius: 6.5, style: .continuous).fill(tint.gradient))
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 13))
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            accessory.labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
    }
}
