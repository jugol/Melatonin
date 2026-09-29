import AppKit
import SwiftUI

/// Crescent outline while sleep is allowed; filled crescent cradling a warm
/// lamp while awake, so the state reads at a glance even in a crowded menu bar.
enum MenuBarIcon {
    private static let size = NSSize(width: 18, height: 18)

    static func image(awake: Bool) -> NSImage {
        let image = NSImage(size: size, flipped: false) { _ in
            let crescent = crescentPath()
            if awake {
                NSColor.labelColor.setFill()
                NSBezierPath(cgPath: crescent).fill()
                drawLamp()
            } else {
                NSColor.labelColor.setStroke()
                let outline = NSBezierPath(cgPath: crescent)
                outline.lineWidth = 1.4
                outline.lineJoinStyle = .round
                outline.stroke()
            }
            return true
        }
        image.isTemplate = !awake
        image.accessibilityDescription = awake ? "Melatonin: awake" : "Melatonin: sleep allowed"
        return image
    }

    private static func crescentPath() -> CGPath {
        let outer = CGPath(ellipseIn: CGRect(x: 1.5, y: 1.5, width: 14, height: 14), transform: nil)
        let bite = CGPath(ellipseIn: CGRect(x: 6.2, y: 5.2, width: 12.5, height: 12.5), transform: nil)
        return outer.subtracting(bite)
    }

    private static func drawLamp() {
        let lamp = NSRect(x: 10.6, y: 9.6, width: 5.6, height: 5.6)
        NSGraphicsContext.saveGraphicsState()
        let glow = NSShadow()
        glow.shadowColor = NSColor(Theme.amber).withAlphaComponent(0.9)
        glow.shadowBlurRadius = 3
        glow.shadowOffset = .zero
        glow.set()
        NSColor(Theme.amber).setFill()
        NSBezierPath(ovalIn: lamp).fill()
        NSGraphicsContext.restoreGraphicsState()

        NSColor(Theme.lampCore).withAlphaComponent(0.9).setFill()
        NSBezierPath(ovalIn: lamp.insetBy(dx: 1.6, dy: 1.6).offsetBy(dx: -0.5, dy: 0.5)).fill()
    }
}

struct MenuBarLabel: View {
    let model: AppModel

    var body: some View {
        Image(nsImage: MenuBarIcon.image(awake: model.isAwake))
    }
}
