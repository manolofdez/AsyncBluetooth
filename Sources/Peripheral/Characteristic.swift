//  Copyright (c) 2021 Manuel Fernandez-Peix Perez. All rights reserved.

import Foundation
@preconcurrency import CoreBluetooth

/// A characteristic of a remote peripheral’s service.
/// - This class acts as a wrapper around `CBCharacteristic`.
public struct Characteristic: Sendable {
    public let cbCharacteristic: CBCharacteristic
    public let uuid: CBUUID
    public let properties: CBCharacteristicProperties
    public let value: Data?
    public let descriptors: [Descriptor]?
    public let isNotifying: Bool

    public init(_ cbCharacteristic: CBCharacteristic) {
        self.cbCharacteristic = cbCharacteristic
        self.uuid = cbCharacteristic.uuid
        self.properties = cbCharacteristic.properties
        self.value = cbCharacteristic.value
        self.descriptors = cbCharacteristic.descriptors?.map { Descriptor($0) }
        self.isNotifying = cbCharacteristic.isNotifying
    }
}
