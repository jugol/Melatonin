import SwiftUI

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
