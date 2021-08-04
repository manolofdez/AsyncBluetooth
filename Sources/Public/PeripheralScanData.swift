import Foundation
import CoreBluetooth

public struct PeripheralScanData {
    public let peripheral: PeripheralType
    public let advertisementData: [String : Any]
    public let rssi: NSNumber
}
