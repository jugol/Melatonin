import AppKit
import SwiftUI

/// The big switch: a night sphere with a crescent when off, a glowing lamp
/// when on.
struct LampOrb: View {
    var isOn: Bool
    var size: CGFloat

    var body: some View {
        ZStack {
            if isOn {
                PhaseAnimator([false, true]) { breathing in
                    Circle()
                        .fill(RadialGradient(
                            colors: [Theme.amber.opacity(0.55), Theme.ember.opacity(0.18), .clear],
                            center: .center, startRadius: size * 0.3, endRadius: size * 0.95
                        ))
                        .frame(width: size * 1.9, height: size * 1.9)
                        .scaleEffect(breathing ? 1.06 : 0.9)
                        .opacity(breathing ? 1 : 0.7)
                } animation: { _ in .easeInOut(duration: 2.6) }
                .transition(.opacity)
            }

            Circle()
                .fill(isOn ? AnyShapeStyle(lampFill) : AnyShapeStyle(nightFill))
                .overlay {
                    // Specular highlight
                    Ellipse()
                        .fill(RadialGradient(
                            colors: [.white.opacity(isOn ? 0.75 : 0.16), .white.opacity(0)],
                            center: .center, startRadius: 0, endRadius: size * 0.2
                        ))
                        .frame(width: size * 0.44, height: size * 0.3)
                        .offset(x: -size * 0.14, y: -size * 0.22)
                }
                .overlay {
                    Circle().strokeBorder(.white.opacity(isOn ? 0.35 : 0.14), lineWidth: 1)
                }
                .shadow(color: isOn ? Theme.ember.opacity(0.55) : .black.opacity(0.25), radius: isOn ? size * 0.22 : size * 0.08, y: isOn ? 0 : size * 0.04)
                .frame(width: size, height: size)

            if !isOn {
                Crescent()
                    .fill(Theme.moon.opacity(0.92))
                    .frame(width: size * 0.36, height: size * 0.36)
                    .offset(x: -size * 0.02, y: size * 0.01)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
        }
        .frame(width: size, height: size)
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: isOn)
        .accessibilityElement()
        .accessibilityLabel(isOn ? Text("Awake") : Text("Sleeps when closed"))
        .accessibilityAddTraits(.isButton)
    }

    private var lampFill: RadialGradient {
        RadialGradient(
            colors: [Theme.lampCore, Theme.amber, Theme.ember, Color(red: 0.86, green: 0.35, blue: 0.14)],
            center: UnitPoint(x: 0.38, y: 0.32), startRadius: 0, endRadius: size * 0.72
        )
    }

    private var nightFill: LinearGradient {
        LinearGradient(colors: [Theme.night, Theme.nightDeep], startPoint: .top, endPoint: .bottom)
    }
}

/// A crescent opening to the upper right.
struct Crescent: Shape {
    func path(in rect: CGRect) -> Path {
        let outer = Path(ellipseIn: rect)
        let bite = Path(ellipseIn: rect
            .insetBy(dx: rect.width * 0.06, dy: rect.height * 0.06)
            .offsetBy(dx: rect.width * 0.3, dy: -rect.height * 0.22))
        return outer.subtracting(bite)
    }
}

/// A small glowing lamp for always-on surfaces like the notch. The pulse is a
/// Core Animation loop, so it costs the app nothing while it runs.
struct GlowOrb: NSViewRepresentable {
    var diameter: CGFloat

    func makeNSView(context: Context) -> GlowOrbView {
        GlowOrbView(diameter: diameter)
    }

    func updateNSView(_ view: GlowOrbView, context: Context) {}

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: GlowOrbView, context: Context) -> CGSize? {
        CGSize(width: diameter, height: diameter)
    }
}

final class GlowOrbView: NSView {
    private let halo = CALayer()
    private let core = CAGradientLayer()

    init(diameter: CGFloat) {
        super.init(frame: NSRect(x: 0, y: 0, width: diameter, height: diameter))
        wantsLayer = true
        layer?.masksToBounds = false

        halo.frame = bounds
        halo.cornerRadius = diameter / 2
        halo.backgroundColor = NSColor(Theme.amber).cgColor
        halo.shadowColor = NSColor(Theme.amber).cgColor
        halo.shadowOffset = .zero
        halo.shadowRadius = diameter * 0.7
        halo.shadowOpacity = 0.9

        core.type = .radial
        core.frame = bounds
        core.cornerRadius = diameter / 2
        core.masksToBounds = true
        core.colors = [NSColor(Theme.lampCore), NSColor(Theme.amber), NSColor(Theme.ember)].map(\.cgColor)
        core.locations = [0, 0.45, 1]
        core.startPoint = CGPoint(x: 0.38, y: 0.66)
        core.endPoint = CGPoint(x: 1.05, y: -0.05)

        layer?.addSublayer(halo)
        layer?.addSublayer(core)

        let glow = CABasicAnimation(keyPath: "shadowOpacity")
        glow.fromValue = 0.25
        glow.toValue = 1.0
        let swell = CABasicAnimation(keyPath: "transform.scale")
        swell.fromValue = 0.9
        swell.toValue = 1.12
        let pulse = CAAnimationGroup()
        pulse.animations = [glow, swell]
        pulse.duration = 1.6
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        halo.add(pulse, forKey: "pulse")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize { bounds.size }
}
