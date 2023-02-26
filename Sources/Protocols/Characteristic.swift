//  Copyright (c) 2023 Manuel Fernandez-Peix Perez. All rights reserved.

import Foundation
import CoreBluetooth

public protocol Characteristic {
    
    associatedtype DescriptorType: Descriptor

    /// The Bluetooth-specific UUID of the characteristic.
    var uuid: CBUUID { get }
    
    var properties: CBCharacteristicProperties { get }
    
    /// The latest value read for this characteristic.
    var value: Data? { get }

    /// A list of the descriptors discovered in this characteristic.
    var descriptors: [DescriptorType]? { get }

    /// A Boolean value that indicates whether the characteristic is currently notifying a subscribed central
    /// of its value.
    var isNotifying: Bool { get }
}
