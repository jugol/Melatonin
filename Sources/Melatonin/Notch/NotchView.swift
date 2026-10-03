import SwiftUI

struct NotchView: View {
    @Environment(AppModel.self) private var model
    let state: NotchState

    private var phase: NotchPhase {
        NotchLayout.phase(expanded: state.isExpanded, model: model)
    }

    var body: some View {
        let metrics = state.metrics
        let size = NotchLayout.size(for: phase, metrics: metrics, banner: model.banner)
        let large = phase == .expanded || phase == .recap
        let shape = NotchShape(
            topRadius: large ? 12 : 7,
            bottomRadius: large ? 28 : 13
        )

        ZStack(alignment: .top) {
            shape
                .fill(.black)
                .shadow(color: .black.opacity(large ? 0.5 : 0), radius: 20, y: 10)
            content(metrics: metrics)
                .frame(width: size.width, height: size.height, alignment: .top)
                .clipShape(shape)
        }
        .frame(width: size.width, height: size.height)
        .opacity(phase == .idle ? 0 : 1)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.spring(response: 0.44, dampingFraction: 0.8), value: phase)
        .animation(.spring(response: 0.44, dampingFraction: 0.8), value: model.banner)
        .environment(\.colorScheme, .dark)
    }

    @ViewBuilder
    private func content(metrics: NotchMetrics) -> some View {
        switch phase {
        case .idle:
            Color.clear
        case .compact:
            CompactWings(notch: metrics.notchSize)
                .transition(.reveal)
        case .banner:
            if let banner = model.banner {
                BannerWings(banner: banner, notch: metrics.notchSize)
                    .id(banner.id)
                    .transition(.reveal)
            }
        case .expanded:
            ExpandedNotch(notch: metrics.notchSize)
                .transition(.reveal)
        case .recap:
            if let recap = model.recap {
                RecapNotchCard(recap: recap, notch: metrics.notchSize)
                    .transition(.reveal)
            }
        }
    }
}

private extension AnyTransition {
    /// Content fades in once the shape has grown, and leaves before it shrinks.
    static var reveal: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.92, anchor: .top))
                .animation(.easeOut(duration: 0.22).delay(0.1)),
            removal: .opacity.animation(.easeIn(duration: 0.08))
        )
    }
}

/// Awake at rest: a breathing lamp on the left, time left on the right.
private struct CompactWings: View {
    @Environment(AppModel.self) private var model
    let notch: CGSize

    var body: some View {
        HStack(spacing: 0) {
            GlowOrb(diameter: 10)
                .frame(width: NotchLayout.compactWing)
            Spacer(minLength: notch.width)
            trailing
                .font(.system(size: 12, weight: .semibold, design: Theme.rounded))
                .foregroundStyle(Theme.amber)
                .frame(width: NotchLayout.compactWing)
        }
        .frame(height: notch.height)
    }

    @ViewBuilder
    private var trailing: some View {
        if model.manualOn, let until = model.manualUntil {
            CountdownText(until: until)
        } else if model.manualOn {
            Image(systemName: "infinity").font(.system(size: 13, weight: .bold))
        } else {
            Image(systemName: "sparkles").font(.system(size: 12, weight: .semibold))
        }
    }
}

/// A two-word message split around the camera housing.
private struct BannerWings: View {
    let banner: Banner
    let notch: CGSize

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 7) {
                icon
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: Theme.rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.leading, 16)
            .frame(width: NotchLayout.bannerWing, alignment: .leading)

            Spacer(minLength: notch.width)

            Text(detail)
                .font(.system(size: 12, weight: .medium, design: Theme.rounded))
                .foregroundStyle(accent)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.trailing, 16)
                .frame(width: NotchLayout.bannerWing, alignment: .trailing)
        }
        .frame(height: notch.height)
    }

    @ViewBuilder
    private var icon: some View {
        switch banner.kind {
        case .awake, .agentStarted:
            GlowOrb(diameter: 10)
        case .asleep:
            Image(systemName: "moon.fill").foregroundStyle(Theme.moon)
        case .stopped(.lowBattery):
            Image(systemName: "battery.25percent").foregroundStyle(.red)
        case .stopped(.overheating):
            Image(systemName: "thermometer.high").foregroundStyle(.orange)
        case .stopped(.timerEnded):
            Image(systemName: "timer").foregroundStyle(Theme.moon)
        case .failed:
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.yellow)
        case .reconnected:
            Image(systemName: "wifi").foregroundStyle(Theme.amber)
        case .offline:
            Image(systemName: "wifi.slash").foregroundStyle(.red)
        case .autoArmed:
            Image(systemName: "sparkles").foregroundStyle(.purple)
        }
    }

    private var title: String {
        switch banner.kind {
        case .awake: String(localized: "Awake")
        case .asleep: String(localized: "Sleep")
        case .stopped(.lowBattery(let percent)): "\(percent)%"
        case .stopped(.overheating): String(localized: "Too hot")
        case .stopped(.timerEnded): String(localized: "Time’s up")
        case .agentStarted(let name): name
        case .failed: String(localized: "Couldn’t switch")
        case .reconnected: String(localized: "Wi-Fi")
        case .offline: String(localized: "Offline")
        case .autoArmed: String(localized: "Auto on")
        }
    }

    private var detail: String {
        switch banner.kind {
        case .awake: String(localized: "Lid can close")
        case .asleep: String(localized: "Back to normal")
        case .stopped: String(localized: "Sleep resumed")
        case .agentStarted: String(localized: "Staying awake")
        case .failed: String(localized: "Open the menu")
        case .reconnected: String(localized: "Reconnected")
        case .offline: String(localized: "Couldn’t reconnect")
        case .autoArmed: String(localized: "Waiting for agents")
        }
    }

    private var accent: Color {
        switch banner.kind {
        case .awake, .agentStarted, .reconnected: Theme.amber
        default: .white.opacity(0.6)
        }
    }
}

/// Hovered: the switch, the timer choices and what's going on, in one glance.
private struct ExpandedNotch: View {
    @Environment(AppModel.self) private var model
    let notch: CGSize

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                HStack(spacing: 5) {
                    Image(systemName: "moon.stars.fill")
                        .foregroundStyle(model.isAwake ? Theme.amber : .white.opacity(0.5))
                    Text(verbatim: "Melatonin")
                        .foregroundStyle(.white.opacity(0.75))
                }
                .font(.system(size: 12, weight: .semibold, design: Theme.rounded))
                Spacer(minLength: notch.width + 24)
                statusPill
            }
            .padding(.horizontal, 24)
            .frame(height: notch.height)

            HStack(spacing: 16) {
                Button { model.toggle() } label: {
                    LampOrb(isOn: model.isAwake, size: 60)
                }
                .buttonStyle(PressableStyle())

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.headline)
                            .font(.system(size: 17, weight: .semibold, design: Theme.rounded))
                            .foregroundStyle(.white)
                        Text(model.detail)
                            .font(.system(size: 11.5))
                            .foregroundStyle(.white.opacity(0.55))
                            .lineLimit(1)
                    }
                    ModeSwitch(height: 26)
                    DurationPicker(height: 22)
                }
            }
            .padding(.horizontal, 26)
            .padding(.top, 14)

            Spacer(minLength: 0)

            HStack(spacing: 14) {
                BatteryLabel(battery: model.battery)
                AgentLabel()
                Spacer()
                Button { WindowPresenter.shared.showPanel() } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.55))
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(.white.opacity(0.08)))
                }
                .buttonStyle(PressableStyle())
                .help("Open Melatonin")
            }
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.white.opacity(0.5))
            .padding(.horizontal, 30)
            .padding(.bottom, 14)
        }
    }

    private var statusPill: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(model.isAwake ? Theme.amber : .white.opacity(0.3))
                .frame(width: 6, height: 6)
                .shadow(color: model.isAwake ? Theme.amber : .clear, radius: 3)
            Text(model.isAwake ? "On" : "Off")
                .font(.system(size: 11, weight: .semibold, design: Theme.rounded))
                .foregroundStyle(model.isAwake ? Theme.amber : .white.opacity(0.5))
        }
    }
}
