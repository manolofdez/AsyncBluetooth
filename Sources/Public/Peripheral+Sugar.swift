import Foundation
import CoreBluetooth

extension Peripheral {
    public func readValue(
        forCharacteristicWithUUID characteristicUUID: CBUUID,
        ofServiceWithUUID serviceUUID: CBUUID
    ) async throws -> Data? {
        guard let characteristic = try await self.findCharacteristic(
            uuid: characteristicUUID,
            ofServiceWithUUID: serviceUUID
        ) else {
            throw BluetoothError.characteristicNotFound
        }
        
        try await self.readValue(for: characteristic)
        
        return characteristic.value
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
