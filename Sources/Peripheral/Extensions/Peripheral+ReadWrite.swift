//  Copyright (c) 2021 Manuel Fernandez-Peix Perez. All rights reserved.

import Foundation
import CoreBluetooth

extension AsyncPeripheral {
    /// Reads and parses the value of a characteristic with a given identifier, of a service with a
    /// given identifier.
    /// - Note: If the service or characteristic has not been discovered, it will attempt to discover it.
    public func readValue<Value>(
        forCharacteristicWithUUID characteristicUUID: UUID,
        ofServiceWithUUID serviceUUID: UUID
    ) async throws -> Value? where Value: PeripheralDataConvertible {
        guard let characteristic = try await self.findCharacteristic(
            uuid: characteristicUUID,
            ofServiceWithUUID: serviceUUID
        ) else {
            throw BluetoothError.characteristicNotFound
        }
        
        try await self.readValue(for: characteristic)
        
        return try characteristic.parsedValue()
    }
    
    /// Writes and parses the value of a characteristic with a given identifier, of a service with a
    /// given identifier.
    /// - Note: If the service or characteristic has not been discovered, it will attempt to discover it.
    public func writeValue<Value>(
        _ value: Value,
        forCharacteristicWithUUID characteristicUUID: UUID,
        ofServiceWithUUID serviceUUID: UUID,
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
    
    /// Sets notifications or indications for the value of a characteristic with a given identifier of a service
    /// with a given identifier
    /// - Note: If the service or characteristic has not been discovered, it will attempt to discover it.
    public func setNotifyValue(
        _ enabled: Bool,
        forCharacteristicWithUUID characteristicUUID: UUID,
        ofServiceWithUUID serviceUUID: UUID
    ) async throws {
        guard let characteristic = try await self.findCharacteristic(
            uuid: characteristicUUID,
            ofServiceWithUUID: serviceUUID
        ) else {
            throw BluetoothError.characteristicNotFound
        }
        
        try await self.setNotifyValue(enabled, for: characteristic)
    }
    
    private func findCharacteristic(
        uuid characteristicUUID: UUID,
        ofServiceWithUUID serviceUUID: UUID
    ) async throws -> Characteristic? {
        guard let service = try await self.findService(uuid: serviceUUID) else {
            return nil
        }
        
        let characteristicCBUUID = CBUUID(nsuuid: characteristicUUID)
        let discoveredCharacteristic: () -> CBCharacteristic? = {
            service.cbService.characteristics?.first(where: { $0.uuid == characteristicCBUUID })
        }
        
        if let cbCharacteristic = discoveredCharacteristic() {
            return Characteristic(cbCharacteristic)
        }
        
        try await self.discoverCharacteristics([characteristicCBUUID], for: service)
        
        guard let cbCharacteristic = discoveredCharacteristic() else {
            return nil
        }
        
        return Characteristic(cbCharacteristic)
    }
    
    private func findService(uuid: UUID) async throws -> Service? {
        let cbUUID = CBUUID(nsuuid: uuid)
        let discoveredService: () -> CBService? = {
            self.cbPeripheral.services?.first(where: { $0.uuid == cbUUID })
        }
        
        if let cbService = discoveredService() {
            return Service(cbService)
        }
        
        try await self.discoverServices([cbUUID])
        
        guard let cbService = discoveredService() else {
            return nil
        }
        
        return Service(cbService)
    }
}
