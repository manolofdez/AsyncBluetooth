//  Copyright (c) 2021 Manuel Fernandez-Peix Perez. All rights reserved.

import Foundation

extension CBCharacteristicWrapper {
    /// Parses the latest read value of the characteristic.
    public func parsedValue<T>() throws -> T? where T: PeripheralDataConvertible {
        guard let value = self.value else {
            return nil
        }
        guard let parsedValue = T.fromData(value) else {
            throw BluetoothError.unableToParseCharacteristicValue
        }
        return parsedValue
    }
}
