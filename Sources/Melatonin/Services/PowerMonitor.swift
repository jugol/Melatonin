import Foundation
import IOKit.ps

struct BatteryStatus: Equatable {
    var percent: Int?
    var isCharging = false
    var onPower = true
    var hasBattery = false

    static let unknown = BatteryStatus()
}

enum PowerMonitor {
    static func battery() -> BatteryStatus {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef]
        else { return .unknown }

        let providing = IOPSGetProvidingPowerSourceType(info)?.takeUnretainedValue() as String?
        let onPower = providing == kIOPMACPowerKey

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any],
                  description[kIOPSTypeKey] as? String == kIOPSInternalBatteryType
            else { continue }
            let current = description[kIOPSCurrentCapacityKey] as? Int ?? 0
            let maximum = description[kIOPSMaxCapacityKey] as? Int ?? 100
            return BatteryStatus(
                percent: maximum > 0 ? current * 100 / maximum : nil,
                isCharging: description[kIOPSIsChargingKey] as? Bool ?? false,
                onPower: onPower,
                hasBattery: true
            )
        }
        return BatteryStatus(onPower: onPower)
    }
}
