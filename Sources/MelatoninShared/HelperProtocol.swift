import Foundation

public enum HelperConstants {
    public static let label = "io.github.jugol.melatonin.helper"
    public static let machServiceName = label
    public static let appBundleIdentifier = "io.github.jugol.Melatonin"

    /// Bump whenever the helper's behavior or protocol changes so the app
    /// knows to reinstall it.
    public static let version = "2"

    public static let installedHelperPath = "/Library/PrivilegedHelperTools/\(label)"
    public static let launchdPlistPath = "/Library/LaunchDaemons/\(label).plist"

    /// Only the Melatonin app may talk to the helper. Release builds signed
    /// with a Developer ID should also pin the team:
    /// `and anchor apple generic and certificate leaf[subject.OU] = "TEAMID"`
    public static let clientRequirement = "identifier \"\(appBundleIdentifier)\""
}

/// The helper's entire surface area: toggle `pmset disablesleep`, and join a
/// Wi-Fi network the user has already saved. Nothing else.
@objc public protocol MelatoninHelperProtocol {
    func version(reply: @escaping (String) -> Void)
    func setSleepDisabled(_ disabled: Bool, reply: @escaping (Bool, String?) -> Void)
    func isSleepDisabled(reply: @escaping (Bool) -> Void)
    func joinWiFi(_ ssid: String, reply: @escaping (Bool, String?) -> Void)
}
