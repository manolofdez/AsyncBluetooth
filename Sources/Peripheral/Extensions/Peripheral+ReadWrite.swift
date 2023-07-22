//  Copyright (c) 2021 Manuel Fernandez-Peix Perez. All rights reserved.

import Foundation
import CoreBluetooth

extension Peripheral {
    /// Reads and parses the value of a characteristic with a given identifier, of a service with a
    /// given identifier.
    /// - Note: If the service or characteristic has not been discovered, it will attempt to discover it.
    public func readValue<Value>(
        forCharacteristicWithUUID characteristicUUID: UUID,
        ofServiceWithUUID serviceUUID: UUID
    ) async throws -> Value? where Value: PeripheralDataConvertible {
        try await self.readValue(
            forCharacteristicWithCBUUID: CBUUID(nsuuid: characteristicUUID),
            ofServiceWithCBUUID: CBUUID(nsuuid: serviceUUID)
        )
    }
    
    /// Reads and parses the value of a characteristic with a given identifier, of a service with a
    /// given identifier.
    /// - Note: If the service or characteristic has not been discovered, it will attempt to discover it.
    public func readValue<Value>(
        forCharacteristicWithCBUUID characteristicCBUUID: CBUUID,
        ofServiceWithCBUUID serviceCBUUID: CBUUID
    ) async throws -> Value? where Value: PeripheralDataConvertible {
        guard let characteristic = try await self.findCharacteristic(
            cbuuid: characteristicCBUUID,
            ofServiceWithCBUUID: serviceCBUUID
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
        try await self.writeValue(
            value,
            forCharacteristicWithCBUUID: CBUUID(nsuuid: characteristicUUID),
            ofServiceWithCBUUID: CBUUID(nsuuid: serviceUUID),
            type: type
        )
    }
    
    /// Writes and parses the value of a characteristic with a given identifier, of a service with a
    /// given identifier.
    /// - Note: If the service or characteristic has not been discovered, it will attempt to discover it.
    public func writeValue<Value>(
        _ value: Value,
        forCharacteristicWithCBUUID characteristicCBUUID: CBUUID,
        ofServiceWithCBUUID serviceCBUUID: CBUUID,
        type: CBCharacteristicWriteType = .withResponse
    ) async throws where Value: PeripheralDataConvertible {
        guard let characteristic = try await self.findCharacteristic(
            cbuuid: characteristicCBUUID,
            ofServiceWithCBUUID: serviceCBUUID
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
        try await self.setNotifyValue(
            enabled,
            forCharacteristicWithCBUUID: CBUUID(nsuuid: characteristicUUID),
            ofServiceWithCBUUID: CBUUID(nsuuid: serviceUUID)
        )
    }
    
    /// Sets notifications or indications for the value of a characteristic with a given identifier of a service
    /// with a given identifier
    /// - Note: If the service or characteristic has not been discovered, it will attempt to discover it.
    public func setNotifyValue(
        _ enabled: Bool,
        forCharacteristicWithCBUUID characteristicCBUUID: CBUUID,
        ofServiceWithCBUUID serviceCBUUID: CBUUID
    ) async throws {
        guard let characteristic = try await self.findCharacteristic(
            cbuuid: characteristicCBUUID,
            ofServiceWithCBUUID: serviceCBUUID
        ) else {
            throw BluetoothError.characteristicNotFound
        }
        
        try await self.setNotifyValue(enabled, for: characteristic)
    }
    
    // MARK: Private helpers
    
    private func findCharacteristic(
        cbuuid characteristicCBUUID: CBUUID,
        ofServiceWithCBUUID serviceCBUUID: CBUUID
    ) async throws -> Characteristic? {
        guard let service = try await self.findService(cbuuid: serviceCBUUID) else {
            return nil
        }
        
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
    
    private func findService(cbuuid: CBUUID) async throws -> Service? {
        let discoveredService: () -> CBService? = {
            self.cbPeripheral.services?.first(where: { $0.uuid == cbuuid })
        }
        
        if let cbService = discoveredService() {
            return Service(cbService)
        }
        
        try await self.discoverServices([cbuuid])
        
        guard let cbService = discoveredService() else {
            return nil
        }
        
        return Service(cbService)
    }
}
