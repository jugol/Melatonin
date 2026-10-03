import SwiftUI

/// Moon, auto, lamp: one switch for whether the Mac may sleep. The thumb
/// slides between them and takes on each position's light.
struct ModeSwitch: View {
    @Environment(AppModel.self) private var model
    var height: CGFloat = 30
    @Namespace private var thumb

    var body: some View {
        HStack(spacing: 0) {
            ForEach(KeepAwakeMode.allCases) { mode in
                let selected = model.mode == mode
                Button { model.setMode(mode) } label: {
                    HStack(spacing: 5) {
                        symbol(mode)
                            .font(.system(size: height * 0.4, weight: .semibold))
                        Text(title(mode))
                            .font(.system(size: height * 0.4, weight: .semibold, design: Theme.rounded))
                            .lineLimit(1)
                    }
                    .foregroundStyle(selected ? foreground(mode) : AnyShapeStyle(.secondary))
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .background {
                        if selected {
                            Capsule()
                                .fill(fill(mode))
                                .shadow(color: glow(mode), radius: 6)
                                .matchedGeometryEffect(id: "thumb", in: thumb)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(PressableStyle(pressedScale: 0.94))
                .help(help(mode))
            }
        }
        .padding(3)
        .background(Capsule().fill(.primary.opacity(0.07)))
        .animation(.spring(response: 0.38, dampingFraction: 0.78), value: model.mode)
    }

    @ViewBuilder
    private func symbol(_ mode: KeepAwakeMode) -> some View {
        switch mode {
        case .off: Image(systemName: "moon.fill")
        // Sparkles twinkle while auto mode is keeping the Mac awake.
        case .auto: Image(systemName: "sparkles").symbolEffect(.pulse, isActive: model.mode == .auto && model.isAwake)
        case .on: Image(systemName: "sun.max.fill")
        }
    }

    private func title(_ mode: KeepAwakeMode) -> LocalizedStringKey {
        switch mode {
        case .off: "Off"
        case .auto: "Auto"
        case .on: "On"
        }
    }

    private func help(_ mode: KeepAwakeMode) -> LocalizedStringKey {
        switch mode {
        case .off: "Sleeps when closed"
        case .auto: "Turns on when an agent starts working"
        case .on: "Until you turn it off · lid can close"
        }
    }

    private func foreground(_ mode: KeepAwakeMode) -> AnyShapeStyle {
        switch mode {
        case .off: AnyShapeStyle(Theme.moon)
        case .auto: AnyShapeStyle(.white)
        case .on: AnyShapeStyle(Theme.ink)
        }
    }

    private func fill(_ mode: KeepAwakeMode) -> AnyShapeStyle {
        switch mode {
        case .off:
            AnyShapeStyle(LinearGradient(colors: [Theme.night, Theme.nightDeep], startPoint: .top, endPoint: .bottom))
        case .auto:
            AnyShapeStyle(LinearGradient(colors: [Color(red: 0.69, green: 0.42, blue: 1.0), Color(red: 0.42, green: 0.30, blue: 0.95)],
                                         startPoint: .top, endPoint: .bottom))
        case .on:
            AnyShapeStyle(LinearGradient(colors: [Theme.amber, Theme.ember.opacity(0.9)], startPoint: .top, endPoint: .bottom))
        }
    }

    private func glow(_ mode: KeepAwakeMode) -> Color {
        switch mode {
        case .off: .black.opacity(0.2)
        case .auto: .purple.opacity(model.isAwake ? 0.55 : 0.3)
        case .on: Theme.amber.opacity(0.5)
        }
    }
}

struct DurationPicker: View {
    @Environment(AppModel.self) private var model
    var height: CGFloat = 26

    var body: some View {
        HStack(spacing: 5) {
            ForEach(AwakeDuration.allCases) { option in
                let selected = option == model.duration
                Button { model.choose(option) } label: {
                    Text(option.label)
                        .font(.system(size: option == .indefinitely ? 15 : 12, weight: .semibold, design: Theme.rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: height)
                        .foregroundStyle(foreground(selected))
                        .background(Capsule().fill(fill(selected)))
                        .contentShape(Capsule())
                }
                .buttonStyle(PressableStyle(pressedScale: 0.9))
            }
        }
        .animation(.snappy(duration: 0.25), value: model.duration)
        .animation(.snappy(duration: 0.25), value: model.isAwake)
    }

    /// Lit only when the user turned Melatonin on, not when auto mode did.
    private var timerRunning: Bool { model.isAwake && model.manualOn }

    private func foreground(_ selected: Bool) -> AnyShapeStyle {
        guard selected else { return AnyShapeStyle(.secondary) }
        return timerRunning ? AnyShapeStyle(Theme.ink) : AnyShapeStyle(.primary)
    }

    private func fill(_ selected: Bool) -> AnyShapeStyle {
        guard selected else { return AnyShapeStyle(.primary.opacity(0.06)) }
        return timerRunning
            ? AnyShapeStyle(LinearGradient(colors: [Theme.amber, Theme.ember.opacity(0.9)], startPoint: .top, endPoint: .bottom))
            : AnyShapeStyle(.primary.opacity(0.14))
    }
}

/// Time left on the timer, ticking once a second without touching the model.
struct CountdownText: View {
    let until: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            Text(Format.countdown(until.timeIntervalSince(context.date)))
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
        }
    }
}

struct BatteryLabel: View {
    let battery: BatteryStatus

    var body: some View {
        if let percent = battery.percent {
            HStack(spacing: 4) {
                Image(systemName: symbol(percent))
                Text(verbatim: "\(percent)%").monospacedDigit()
                if battery.isCharging {
                    Image(systemName: "bolt.fill").font(.system(size: 8, weight: .bold))
                }
            }
        } else {
            Label("On power", systemImage: "powerplug.fill")
        }
    }

    private func symbol(_ percent: Int) -> String {
        switch percent {
        case ..<13: "battery.0percent"
        case ..<38: "battery.25percent"
        case ..<63: "battery.50percent"
        case ..<88: "battery.75percent"
        default: "battery.100percent"
        }
    }
}

/// "Claude Code and Hermes working", or the first idle agent.
struct AgentLabel: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if let working = model.workingAgentList {
            label(Text("\(working) working"), active: true)
        } else if let idle = model.agents.first {
            label(Text("\(idle.name) idle"), active: false)
        }
    }

    private func label(_ text: Text, active: Bool) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(active ? Theme.amber : Color.secondary.opacity(0.5))
                .frame(width: 6, height: 6)
            text.lineLimit(1)
        }
    }
}
