import Foundation

/// The app's UI language. It follows macOS unless the user picks one from the
/// menu; the choice is stored as this app's own AppleLanguages and takes
/// effect when the app relaunches.
enum AppLanguage {
    static let supported: [(code: String, name: String)] = [
        ("en", "English"),
        ("ko", "한국어"),
        ("zh-Hans", "简体中文"),
        ("ja", "日本語"),
        ("es", "Español"),
        ("fr", "Français"),
        ("de", "Deutsch"),
        ("pt-BR", "Português (Brasil)"),
        ("ru", "Русский"),
        ("ar", "العربية"),
        ("hi", "हिन्दी"),
        ("id", "Bahasa Indonesia"),
    ]

    /// The language picked in the app, or nil when following macOS.
    static var override: String? {
        guard let identifier = Bundle.main.bundleIdentifier,
              let languages = UserDefaults.standard.persistentDomain(forName: identifier)?["AppleLanguages"] as? [String]
        else { return nil }
        return languages.first
    }

    static func set(_ code: String?) {
        if let code {
            UserDefaults.standard.set([code], forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
    }
}
