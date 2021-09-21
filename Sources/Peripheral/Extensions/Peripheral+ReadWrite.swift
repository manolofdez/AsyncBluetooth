import Foundation
import CoreBluetooth

extension Peripheral {
    /// Reads and parses the value of a characteristic with a given identifier, of a service with a
    /// given identifier.
    /// - Note: If the service or characteristic has not been discovered, it will attempt to discover it.
    public func readValue<Value>(
        forCharacteristicWithIdentifier characteristicIdentifier: CBUUID,
        ofServiceWithUUID serviceIdentifier: CBUUID
    ) async throws -> Value? where Value: PeripheralDataConvertible {
        guard let characteristic = try await self.findCharacteristic(
            uuid: characteristicIdentifier,
            ofServiceWithUUID: serviceIdentifier
        ) else {
            throw BluetoothError.characteristicNotFound
        }
        
        try await self.readValue(for: characteristic)
        
        guard let data = characteristic.value else {
            return nil
        }
        
        guard let value = Value.fromData(data) else {
            throw BluetoothError.unableToParseCharacteristicValue
        }
        
        return value
    }
    
    /// Writes and parses the value of a characteristic with a given identifier, of a service with a
    /// given identifier.
    /// - Note: If the service or characteristic has not been discovered, it will attempt to discover it.
    public func writeValue<Value>(
        _ value: Value,
        forCharacteristicWithUUID characteristicUUID: CBUUID,
        ofServiceWithUUID serviceUUID: CBUUID,
        type: CBCharacteristicWriteType = .withResponse
    ) async throws where Value: PeripheralDataConvertible {
        guard let characteristic = try await self.findCharacteristic(
            uuid: characteristicUUID,
            ofServiceWithUUID: serviceUUID
        ) else {
            throw BluetoothError.characteristicNotFound
        }

        guard let data = value.toData() else {
            throw BluetoothError.unableToConvertValueToData
        }
        
        try await self.writeValue(data, for: characteristic, type: type)
    }
    
    private func findCharacteristic(
        uuid characteristicUUID: CBUUID,
        ofServiceWithUUID serviceUUID: CBUUID
    ) async throws -> CBCharacteristic? {
        guard let service = try await self.findService(uuid: serviceUUID) else {
            return nil
        }
        
        let discoveredCharacteristic: () -> CBCharacteristic? = {
            service.characteristics?.first(where: { $0.uuid == characteristicUUID })
        }
        
        if let characteristic = discoveredCharacteristic() {
            return characteristic
        }
        
        return discoveredCharacteristic()
    }
    
    private func findService(uuid: CBUUID) async throws -> CBService? {
        let discoveredService: () -> CBService? = {
            self.cbPeripheral.services?.first(where: { $0.uuid == uuid })
        }
        
        if let service = discoveredService() {
            return service
        }
        
        try await self.discoverServices([uuid])
        
        return discoveredService()
    }
}
