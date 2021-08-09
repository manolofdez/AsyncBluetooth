import Foundation
import CoreBluetooth

/// Represents a single value gathered when scanning for peripheral.
public struct PeripheralScanData {
    public let peripheral: PeripheralType
    public let advertisementData: [String : Any]
    public let rssi: NSNumber
}
