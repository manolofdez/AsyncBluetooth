//  Copyright (c) 2023 Manuel Fernandez-Peix Perez. All rights reserved.

import Foundation
import CoreBluetooth

public protocol Descriptor {
    /// The Bluetooth-specific UUID of the descriptor.
    var uuid: CBUUID { get }
    
    /// The value of the descriptor. The corresponding value types for the various descriptors are detailed in `CBUUID.h`.
    var value: Any? { get }
}
