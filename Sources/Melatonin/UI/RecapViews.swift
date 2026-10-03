import SwiftUI

extension TimeInterval {
    /// "2h 14m", "45m", in the app's language.
    var spokenLength: String {
        let minutes = Swift.max(1, Int((self / 60).rounded()))
        return Duration.seconds(minutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .narrow))
    }
}

extension AwayRecap {
    var headline: String {
        if awake.isEmpty { return String(localized: "Your Mac went to sleep") }
        if awakeWholeTime { return String(localized: "Awake the whole time") }
        let length = awakeTime.spokenLength
        return String(localized: "Kept awake for \(length)")
    }

    /// How it ended, or that it hasn't.
    var ending: String {
        if awake.isEmpty { return String(localized: "Turn on auto mode so agents can finish") }
        if stillAwake {
            guard !stillWorking.isEmpty else { return String(localized: "Still awake") }
            let names = stillWorking.formatted(.list(type: .and))
            return String(localized: "\(names) still working")
        }
        if let stop, let stopDate {
            let reason: String
            switch stop {
            case .lowBattery(let percent):
                let level = "\(percent)%"
                reason = String(localized: "Stopped at \(level) battery")
            case .overheating: reason = String(localized: "Stopped because your Mac got hot")
            case .timerEnded: reason = String(localized: "Timer ended")
            }
            return "\(reason) · \(stopDate.formatted(date: .omitted, time: .shortened))"
        }
        let time = (awake.last?.end ?? end).formatted(date: .omitted, time: .shortened)
        return String(localized: "Sleep resumed at \(time)")
    }

    /// "Claude Code 1h 52m · Hermes 40m"
    func agentSummary(limit: Int) -> String? {
        guard !agents.isEmpty else { return nil }
        return agents.prefix(limit).map { "\($0.name) \($0.seconds.spokenLength)" }.joined(separator: " · ")
    }
}

/// The absence as a bar: lit where Melatonin kept the Mac awake, underlined
/// where agents worked, dotted where Wi-Fi came back (or didn't).
struct RecapTimeline: View {
    let recap: AwayRecap
    var track: Color
    var labels: Color
    var glows = false

    var body: some View {
        VStack(spacing: 5) {
            GeometryReader { geometry in
                let width = geometry.size.width
                ZStack(alignment: .topLeading) {
                    Capsule().fill(track).frame(width: width, height: 6)
                    ForEach(Array(recap.awake.enumerated()), id: \.offset) { _, span in
                        Capsule()
                            .fill(LinearGradient(colors: [Theme.amber, Theme.ember], startPoint: .leading, endPoint: .trailing))
                            .frame(width: length(span, in: width), height: 6)
                            .shadow(color: glows ? Theme.amber.opacity(0.7) : .clear, radius: 4)
                            .offset(x: x(span.start, in: width))
                    }
                    ForEach(Array(recap.working.enumerated()), id: \.offset) { _, span in
                        Capsule()
                            .fill(Color.purple.opacity(0.85))
                            .frame(width: length(span, in: width), height: 2)
                            .offset(x: x(span.start, in: width), y: 10)
                    }
                    ForEach(Array(recap.reconnects.enumerated()), id: \.offset) { _, date in
                        marker(.cyan).offset(x: x(date, in: width) - 4, y: -1)
                    }
                    ForEach(Array(recap.failedReconnects.enumerated()), id: \.offset) { _, date in
                        marker(.red).offset(x: x(date, in: width) - 4, y: -1)
                    }
                }
            }
            .frame(height: 12)

            HStack {
                Text(recap.start.formatted(date: .omitted, time: .shortened))
                Spacer()
                Text(recap.end.formatted(date: .omitted, time: .shortened))
            }
            .font(.system(size: 10, weight: .medium, design: Theme.rounded))
            .monospacedDigit()
            .foregroundStyle(labels)
        }
    }

    private func x(_ date: Date, in width: CGFloat) -> CGFloat {
        let fraction = date.timeIntervalSince(recap.start) / Swift.max(recap.duration, 1)
        return width * CGFloat(Swift.min(Swift.max(fraction, 0), 1))
    }

    private func length(_ span: AwayRecap.Span, in width: CGFloat) -> CGFloat {
        Swift.max(4, x(span.end, in: width) - x(span.start, in: width))
    }

    private func marker(_ color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .overlay(Circle().strokeBorder(.black.opacity(0.6), lineWidth: 1.5))
    }
}

/// Agents, Wi-Fi and battery, as small labels.
struct RecapStats: View {
    let recap: AwayRecap
    var agentLimit = 2
    var includesAgents = true
    var includesOthers = true

    var body: some View {
        HStack(spacing: 12) {
            if includesAgents, let agents = recap.agentSummary(limit: agentLimit) {
                stat("sparkles", .purple, agents)
            }
            if includesOthers {
                if !recap.reconnects.isEmpty {
                    stat("wifi", .cyan, String(localized: "Reconnected \(recap.reconnects.count)×"))
                } else if !recap.failedReconnects.isEmpty {
                    stat("wifi.slash", .red, String(localized: "Couldn’t reconnect"))
                }
                if recap.ranOnBattery, let start = recap.batteryStart.percent, let end = recap.batteryEnd.percent {
                    stat("battery.50percent", .green, "\(start)% → \(end)%")
                }
            }
        }
        .lineLimit(1)
    }

    private func stat(_ symbol: String, _ tint: Color, _ text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol).foregroundStyle(tint)
            Text(verbatim: text)
        }
        .fixedSize()
    }
}

/// The summary hanging from the notch when the user comes back.
struct RecapNotchCard: View {
    @Environment(AppModel.self) private var model
    let recap: AwayRecap
    let notch: CGSize

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                HStack(spacing: 5) {
                    Image(systemName: "moon.stars.fill").foregroundStyle(Theme.amber)
                    Text("While you were away")
                        .foregroundStyle(.white.opacity(0.75))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .font(.system(size: 12, weight: .semibold, design: Theme.rounded))
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: notch.width + 16)
                Text(recap.duration.spokenLength)
                    .font(.system(size: 12, weight: .semibold, design: Theme.rounded))
                    .foregroundStyle(Theme.amber)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 24)
            .frame(height: notch.height)

            HStack(spacing: 14) {
                LampOrb(isOn: !recap.awake.isEmpty, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(recap.headline)
                        .font(.system(size: 17, weight: .semibold, design: Theme.rounded))
                        .foregroundStyle(.white)
                    Text(recap.ending)
                        .font(.system(size: 11.5))
                        .foregroundStyle(.white.opacity(0.55))
                }
                .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 28)
            .padding(.top, 12)

            RecapTimeline(recap: recap, track: .white.opacity(0.1), labels: .white.opacity(0.4), glows: true)
                .padding(.horizontal, 30)
                .padding(.top, 12)

            Spacer(minLength: 0)

            HStack(spacing: 12) {
                ViewThatFits(in: .horizontal) {
                    RecapStats(recap: recap)
                    RecapStats(recap: recap, agentLimit: 1)
                    RecapStats(recap: recap, includesOthers: false)
                }
                Spacer(minLength: 0)
                Button { model.dismissRecap() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.55))
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(.white.opacity(0.08)))
                }
                .buttonStyle(PressableStyle())
                .help("Dismiss")
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.white.opacity(0.55))
            .padding(.horizontal, 30)
            .padding(.bottom, 14)
        }
    }
}

/// The same summary in the menu, kept until dismissed.
struct RecapCard: View {
    @Environment(AppModel.self) private var model
    let recap: AwayRecap

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 5) {
                Image(systemName: "moon.stars.fill").foregroundStyle(Theme.ember)
                Text("While you were away")
                Text(verbatim: "· \(recap.duration.spokenLength)").foregroundStyle(.secondary)
                Spacer(minLength: 4)
                Button { model.dismissRecap() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(.primary.opacity(0.07)))
                }
                .buttonStyle(PressableStyle())
                .help("Dismiss")
            }
            .font(.system(size: 11, weight: .semibold))
            .lineLimit(1)

            VStack(alignment: .leading, spacing: 1) {
                Text(recap.headline)
                    .font(.system(size: 15, weight: .semibold, design: Theme.rounded))
                Text(recap.ending)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            RecapTimeline(recap: recap, track: .primary.opacity(0.08), labels: .secondary)

            VStack(alignment: .leading, spacing: 4) {
                RecapStats(recap: recap, agentLimit: 2, includesOthers: false)
                RecapStats(recap: recap, includesAgents: false)
            }
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.amber.opacity(0.10))
                .strokeBorder(Theme.amber.opacity(0.32), lineWidth: 0.5)
        )
    }
}
