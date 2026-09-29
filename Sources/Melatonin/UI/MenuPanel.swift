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
                Button("Show activity log") {
                    NSWorkspace.shared.open(ActivityLog.url)
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
            } else if model.isAwake, !model.manualOn {
                Label("Auto", systemImage: "sparkles")
                    .font(.system(size: 11, weight: .semibold, design: Theme.rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.purple.gradient))
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
    @State private var explainsAuto = false

    var body: some View {
        @Bindable var model = model
        @Bindable var connection = model.connection
        VStack(spacing: 0) {
            SettingRow(
                symbol: "sparkles", tint: .purple, title: "Auto-on while agents work", subtitle: autoSummary,
                info: { withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { explainsAuto.toggle() } }
            ) {
                Toggle("", isOn: $model.autoForAgents)
            }
            if explainsAuto {
                AutoExplainer()
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            SettingRow(symbol: "wifi", tint: .blue, title: "Stay online", subtitle: connection.summary) {
                HStack(spacing: 8) {
                    Button {
                        WindowPresenter.shared.showConnection()
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .help("Stay online")
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

    /// Says what the switch does when off, and what it's doing when on.
    private var autoSummary: String {
        guard model.autoForAgents else {
            return String(localized: "Turns on by itself while Claude Code, Codex and others work")
        }
        if model.autoPaused { return String(localized: "Auto paused until agents finish") }
        if let working = model.workingAgentList {
            return String(localized: "\(working) working · keeping awake")
        }
        return String(localized: "Waiting for an agent to start")
    }
}

/// What auto mode does, as a four-step picture plus the on/off difference.
struct AutoExplainer: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 2) {
                step("Agent starts") { symbol("sparkles", .purple) }
                arrow
                step("Awake") { LampOrb(isOn: true, size: 18).frame(width: 26, height: 26) }
                arrow
                step("Done + 3 min") { symbol("clock", .secondary) }
                arrow
                step("Sleep resumed") { symbol("moon.fill", Theme.night) }
            }
            VStack(alignment: .leading, spacing: 6) {
                explanation("When on", "Melatonin turns itself on as soon as an AI agent starts working, and lets your Mac sleep again 3 minutes after it finishes.")
                explanation("When off", "Melatonin only turns on when you tap the moon.")
            }
            Text("Agents waiting for your input don’t count. Works with Claude Code, Codex, Hermes, OpenCode, T3 Code, Gemini CLI and more.")
                .font(.system(size: 10.5))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.purple.opacity(0.08))
                .strokeBorder(Color.purple.opacity(0.25), lineWidth: 0.5)
        )
    }

    private func step(_ label: LocalizedStringKey, @ViewBuilder icon: () -> some View) -> some View {
        VStack(spacing: 4) {
            icon()
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    private func symbol(_ name: String, _ tint: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: 26, height: 26)
            .background(Circle().fill(tint.opacity(0.14)))
    }

    private var arrow: some View {
        Image(systemName: "chevron.forward")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.tertiary)
            .frame(height: 26)
    }

    private func explanation(_ title: LocalizedStringKey, _ body: LocalizedStringKey) -> some View {
        (Text(title).fontWeight(.semibold) + Text(verbatim: "  ") + Text(body).foregroundStyle(.secondary))
            .font(.system(size: 11))
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct SettingRow<Accessory: View>: View {
    let symbol: String
    let tint: Color
    let title: LocalizedStringKey
    var subtitle: String?
    /// Shows an ⓘ button beside the title.
    var info: (() -> Void)?
    @ViewBuilder var accessory: Accessory

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(RoundedRectangle(cornerRadius: 6.5, style: .continuous).fill(tint.gradient))
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(title).font(.system(size: 13))
                    if let info {
                        Button(action: info) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.borderless)
                        .help("How it works")
                    }
                }
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            accessory.labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
    }
}
