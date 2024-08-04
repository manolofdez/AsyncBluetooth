//  Copyright (c) 2021 Manuel Fernandez-Peix Perez. All rights reserved.

import Foundation
import CoreBluetooth

/// Represents a single value gathered when scanning for peripheral.
public struct ScanData: Sendable {
    public let peripheral: Peripheral
    /// A dictionary containing any advertisement and scan response data.
    public let advertisementData: [String : any Sendable]
    /// The current RSSI of the peripheral, in dBm. A value of 127 is reserved and indicates the RSSI
    /// was not available.
    public let rssi: NSNumber
}
