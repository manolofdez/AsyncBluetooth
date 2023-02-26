//  Copyright (c) 2021 Manuel Fernandez-Peix Perez. All rights reserved.

import Foundation
import CoreBluetooth

public protocol Service {
    associatedtype CharacteristicType: Characteristic
    associatedtype ServiceType: Service
    
    /// The Bluetooth-specific UUID of the service.
    var uuid: CBUUID { get }
    
    /// A Boolean value that indicates whether the type of service is primary or secondary. A primary service
    /// describes the primary function of a device. A secondary service describes a service that’s relevant only
    /// in the context of another service that references it.
    var isPrimary: Bool { get }
    
    /// A list of included services discovered in this service.
    var includedServices: [ServiceType]? { get }
    
    /// A list of characteristics discovered in this service.
    var characteristics: [CharacteristicType]? { get }
}
