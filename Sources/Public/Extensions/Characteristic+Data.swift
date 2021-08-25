import Foundation

extension Characteristic {
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
