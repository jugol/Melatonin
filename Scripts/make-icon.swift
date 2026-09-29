// Draws the Melatonin app icon at 1024×1024.
// Usage: swift Scripts/make-icon.swift <output.png>
import AppKit

let size: CGFloat = 1024
let output = CommandLine.arguments.dropFirst().first ?? "icon.png"

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

/// Apple-style continuous-corner squircle (superellipse).
func squircle(in rect: CGRect, exponent n: CGFloat = 5) -> CGPath {
    let path = CGMutablePath()
    let a = rect.width / 2, b = rect.height / 2
    let steps = 720
    for i in 0...steps {
        let t = CGFloat(i) / CGFloat(steps) * 2 * .pi
        let c = cos(t), s = sin(t)
        let x = rect.midX + a * (c < 0 ? -1 : 1) * pow(abs(c), 2 / n)
        let y = rect.midY + b * (s < 0 ? -1 : 1) * pow(abs(s), 2 / n)
        i == 0 ? path.move(to: CGPoint(x: x, y: y)) : path.addLine(to: CGPoint(x: x, y: y))
    }
    path.closeSubpath()
    return path
}

let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(
    data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0,
    space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!

let body = CGRect(x: 100, y: 100, width: 824, height: 824)
let shape = squircle(in: body)

// Drop shadow
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: color(0x000000, 0.35))
ctx.addPath(shape)
ctx.setFillColor(color(0x10132A))
ctx.fillPath()
ctx.restoreGState()

ctx.saveGState()
ctx.addPath(shape)
ctx.clip()

// Night sky
let sky = CGGradient(colorsSpace: space, colors: [color(0x323A72), color(0x1A1E42), color(0x0B0D1F)] as CFArray, locations: [0, 0.55, 1])!
ctx.drawLinearGradient(sky, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])

// Stars
let stars: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [
    (250, 800, 5, 0.85), (345, 862, 3, 0.55), (760, 830, 6, 0.9), (842, 736, 3.5, 0.6),
    (668, 882, 3, 0.5), (205, 640, 3, 0.45), (820, 560, 4, 0.55), (455, 812, 2.5, 0.45),
    (600, 760, 2, 0.35), (175, 360, 2.5, 0.35), (860, 330, 3, 0.4),
]
for (x, y, r, a) in stars {
    ctx.setFillColor(color(0xFFFFFF, a))
    ctx.fillEllipse(in: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r))
}

let lampCenter = CGPoint(x: 566, y: 548)
let lampRadius: CGFloat = 92

// Lamplight washing the sky
let wash = CGGradient(colorsSpace: space, colors: [color(0xFFB547, 0.62), color(0xFF8A3C, 0.22), color(0xFF7A2E, 0)] as CFArray, locations: [0, 0.4, 1])!
ctx.drawRadialGradient(wash, startCenter: lampCenter, startRadius: 0, endCenter: lampCenter, endRadius: 440, options: [])

// Crescent moon
let outer = CGPath(ellipseIn: CGRect(x: 470 - 262, y: 480 - 262, width: 524, height: 524), transform: nil)
let bite = CGPath(ellipseIn: CGRect(x: 600 - 238, y: 590 - 238, width: 476, height: 476), transform: nil)
let crescent = outer.subtracting(bite)
ctx.saveGState()
ctx.setShadow(offset: .zero, blur: 40, color: color(0xFFE9C2, 0.35))
ctx.addPath(crescent)
ctx.setFillColor(color(0xF4EAD6))
ctx.fillPath()
ctx.restoreGState()
ctx.saveGState()
ctx.addPath(crescent)
ctx.clip()
let moonShade = CGGradient(colorsSpace: space, colors: [color(0xFFF8EA), color(0xEADCC0), color(0xC9B58F)] as CFArray, locations: [0, 0.6, 1])!
ctx.drawLinearGradient(moonShade, start: CGPoint(x: 560, y: 560), end: CGPoint(x: 260, y: 240), options: [])
// Lamplight catching the moon's inner edge
let rim = CGGradient(colorsSpace: space, colors: [color(0xFFB04A, 0.55), color(0xFFB04A, 0)] as CFArray, locations: [0, 1])!
ctx.drawRadialGradient(rim, startCenter: lampCenter, startRadius: lampRadius, endCenter: lampCenter, endRadius: 330, options: [])
ctx.restoreGState()

// The lamp
ctx.saveGState()
ctx.setShadow(offset: .zero, blur: 120, color: color(0xFFA040, 1))
ctx.setFillColor(color(0xFFB547))
for _ in 0..<2 {
    ctx.fillEllipse(in: CGRect(x: lampCenter.x - lampRadius, y: lampCenter.y - lampRadius, width: 2 * lampRadius, height: 2 * lampRadius))
}
ctx.restoreGState()
ctx.saveGState()
ctx.addEllipse(in: CGRect(x: lampCenter.x - lampRadius, y: lampCenter.y - lampRadius, width: 2 * lampRadius, height: 2 * lampRadius))
ctx.clip()
let lamp = CGGradient(colorsSpace: space, colors: [color(0xFFFCF0), color(0xFFD57E), color(0xFF9A3C), color(0xE8672B)] as CFArray, locations: [0, 0.3, 0.72, 1])!
let highlight = CGPoint(x: lampCenter.x - 30, y: lampCenter.y + 34)
ctx.drawRadialGradient(lamp, startCenter: highlight, startRadius: 0, endCenter: lampCenter, endRadius: lampRadius * 1.15, options: [.drawsAfterEndLocation])
ctx.restoreGState()

// Soft top sheen and hairline edge
let sheen = CGGradient(colorsSpace: space, colors: [color(0xFFFFFF, 0.10), color(0xFFFFFF, 0)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(sheen, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 640), options: [])
ctx.restoreGState()

ctx.addPath(shape)
ctx.setStrokeColor(color(0xFFFFFF, 0.12))
ctx.setLineWidth(2)
ctx.strokePath()

let image = ctx.makeImage()!
let rep = NSBitmapImageRep(cgImage: image)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: output))
print("Wrote \(output)")
