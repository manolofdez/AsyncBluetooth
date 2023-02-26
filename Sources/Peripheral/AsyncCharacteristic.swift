//  Copyright (c) 2021 Manuel Fernandez-Peix Perez. All rights reserved.

import Foundation
import CoreBluetooth

/// A characteristic of a remote peripheral’s service.
/// - This class acts as a wrapper around `CBCharacteristic`.
public struct AsyncCharacteristic {
    public let cbCharacteristic: CBCharacteristic
    
    public init(_ cbCharacteristic: CBCharacteristic) {
        self.cbCharacteristic = cbCharacteristic
    }
    
    /// The Bluetooth-specific UUID of the characteristic.
    public var uuid: CBUUID {
        self.cbCharacteristic.uuid
    }
    
    public var properties: CBCharacteristicProperties {
        self.cbCharacteristic.properties
    }
    
    /// The latest value read for this characteristic.
    public var value: Data? {
        self.cbCharacteristic.value
    }

    /// A list of the descriptors discovered in this characteristic.
    public var descriptors: [AsyncDescriptor]? {
        self.cbCharacteristic.descriptors?.map { AsyncDescriptor($0) }
    }

    /// A Boolean value that indicates whether the characteristic is currently notifying a subscribed central
    /// of its value.
    public var isNotifying: Bool {
        self.cbCharacteristic.isNotifying
    }
}
