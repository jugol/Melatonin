import SwiftUI

/// Night and lamplight: a dark moon when your Mac may sleep, a warm amber
/// lamp when it's staying up.
enum Theme {
    static let lampCore = Color(red: 1.00, green: 0.96, blue: 0.87)  // #FFF5DE
    static let amber = Color(red: 1.00, green: 0.71, blue: 0.28)     // #FFB547
    static let ember = Color(red: 1.00, green: 0.48, blue: 0.18)     // #FF7A2E
    static let ink = Color(red: 0.25, green: 0.13, blue: 0.02)       // text on amber
    static let night = Color(red: 0.20, green: 0.23, blue: 0.36)     // #343A5C
    static let nightDeep = Color(red: 0.07, green: 0.08, blue: 0.15) // #121427
    static let moon = Color(red: 0.95, green: 0.91, blue: 0.83)      // #F2E8D4

    static let rounded = Font.Design.rounded
}

struct PressableStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.93

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

enum Format {
    static func countdown(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval.rounded(.up)))
        let hours = seconds / 3600, minutes = seconds % 3600 / 60, rest = seconds % 60
        return hours > 0
            ? String(format: "%d:%02d:%02d", hours, minutes, rest)
            : String(format: "%d:%02d", minutes, rest)
    }
}
