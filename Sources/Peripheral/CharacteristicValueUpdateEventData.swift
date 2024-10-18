// Copyright (c) 2024 Manuel Fernandez. All rights reserved.

import Foundation

public struct CharacteristicValueUpdateEventData {
    /// The characteristic whose value was updated.
    public let characteristic: Characteristic
    /// The value the characteristic changed to. We store it separately from the characteristic
    /// to avoid data races, given that the underlying CBCharacteristic's value might change
    /// before clients receive the publisher's value.
    public let value: Data?
    
    init(characteristic: Characteristic) {
        self.characteristic = characteristic
        self.value = characteristic.value
    }
}
