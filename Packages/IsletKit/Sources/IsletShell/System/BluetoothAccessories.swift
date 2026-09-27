import Foundation
import IOBluetooth
import IsletCore

/// Battery levels of connected Bluetooth accessories. AirPods and Beats report them through properties IOBluetooth
/// does not document; they are read defensively and simply missing when a device does not have them.
@MainActor
enum BluetoothAccessories {
    static func battery(forName name: String) -> AccessoryBattery? {
        guard let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else { return nil }
        let wanted = name.lowercased()
        guard let device = devices.first(where: { device in
            guard device.isConnected(), let deviceName = device.name?.lowercased() else { return false }
            return deviceName == wanted || wanted.contains(deviceName) || deviceName.contains(wanted)
        }) else { return nil }
        func read(_ key: String) -> Int? {
            guard device.responds(to: Selector(key)), let value = device.value(forKey: key) as? NSNumber else { return nil }
            return AccessoryBattery.level(value.intValue)
        }
        let battery = AccessoryBattery(
            left: read("batteryPercentLeft"),
            right: read("batteryPercentRight"),
            caseLevel: read("batteryPercentCase"),
            single: read("batteryPercentSingle") ?? read("batteryPercentCombined")
        )
        return battery.isEmpty ? nil : battery
    }
}
