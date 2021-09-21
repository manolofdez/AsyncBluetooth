import Foundation
import CoreBluetooth

/// Represents a single value gathered when scanning for peripheral.
public struct ScanData {
    public let peripheral: Peripheral
    /// A dictionary containing any advertisement and scan response data.
    public let advertisementData: [String : Any]
    /// The current RSSI of the peripheral, in dBm. A value of 127 is reserved and indicates the RSSI
    /// was not available.
    public let rssi: NSNumber
}
