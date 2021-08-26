import Foundation
import CoreBluetooth
import Combine
import os.log

/// A wrapper around `CBPeripheral`, used to interact with a remote peripheral.
public class Peripheral {
    
    fileprivate class DelegateWrapper: NSObject {
        private weak var peripheral: Peripheral?
        
        init(owner peripheral: Peripheral) {
            self.peripheral = peripheral
        }
    }
    
    private static let logger = Logger(
        subsystem: Bundle(for: Peripheral.self).bundleIdentifier ?? "",
        category: "peripheral"
    )
    
    public lazy var characteristicValueUpdatedPublisher: AnyPublisher<CharacteristicValueUpdatedEventData, Never> = {
        self.characteristicValueUpdatedSubject.eraseToAnyPublisher()
    }()
    
    let cbPeripheral: CBPeripheral
    
    public var name: String? {
        self.cbPeripheral.name
    }
    
    var identifier: UUID {
        self.cbPeripheral.identifier
    }
    
    private let characteristicValueUpdatedSubject = PassthroughSubject<CharacteristicValueUpdatedEventData, Never>()
    
    private let readRSSIStorage = CheckedContinuationStorage<NSNumber, Error>()
    private let discoverServiceStorage = CheckedContinuationStorage<Void, Error>()
    private let discoverIncludedServicesStorage = CheckedContinuationMapStorage<CBUUID, Void, Error>()
    private let discoverCharacteristicsStorage = CheckedContinuationMapStorage<CBUUID, Void, Error>()
    private let readCharacteristicValueStorage = CheckedContinuationMapStorage<CBUUID, Void, Error>()
    private let writeCharacteristicValueStorage = CheckedContinuationMapStorage<CBUUID, Void, Error>()
    private let setNotifyValueStorage = CheckedContinuationMapStorage<CBUUID, Void, Error>()
    private let discoverDescriptorsStorage = CheckedContinuationMapStorage<CBUUID, Void, Error>()
    private let readDescriptorValueStorage = CheckedContinuationMapStorage<CBUUID, Void, Error>()
    private let writeDescriptorValueStorage = CheckedContinuationMapStorage<CBUUID, Void, Error>()
    private let openL2CAPChannelStorage = CheckedContinuationStorage<Void, Error>()
    
    private lazy var cbPeripheralDelegate: CBPeripheralDelegate = {
        DelegateWrapper(owner: self)
    }()
    
    init(_ cbPeripheral: CBPeripheral) {
        self.cbPeripheral = cbPeripheral
    }
    
    public func readRSSI() async throws -> NSNumber {
        try await self.readRSSIStorage.perform { [weak self] in
            self?.cbPeripheral.readRSSI()
        }
    }
    
    public func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int {
        self.cbPeripheral.maximumWriteValueLength(for: type)
    }
    
    public func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic) async throws {
        try await self.setNotifyValueStorage.perform(withKey: characteristic.uuid) { [weak self] in
            self?.cbPeripheral.setNotifyValue(enabled, for: characteristic)
        }
    }
    
    @available(iOS 11.0, *)
    public func openL2CAPChannel(_ PSM: CBL2CAPPSM) async throws {
        try await self.openL2CAPChannelStorage.perform { [weak self] in
            self?.cbPeripheral.openL2CAPChannel(PSM)
        }
    }
    
    func discoverServices(_ serviceUUIDs: [CBUUID]?) async throws {
        try await self.discoverServiceStorage.perform { [weak self] in
            self?.cbPeripheral.discoverServices(serviceUUIDs)
        }
    }
    
    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: CBService) async throws {
        try await self.discoverIncludedServicesStorage.perform(withKey: service.uuid) { [weak self] in
            self?.cbPeripheral.discoverIncludedServices(includedServiceUUIDs, for: service)
        }
    }
    
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService) async throws {
        try await self.discoverCharacteristicsStorage.perform(withKey: service.uuid) { [weak self] in
            self?.cbPeripheral.discoverCharacteristics(characteristicUUIDs, for: service)
        }
    }
    
    func readValue(for characteristic: CBCharacteristic) async throws {
        try await self.readCharacteristicValueStorage.perform(withKey: characteristic.uuid) { [weak self] in
            self?.cbPeripheral.readValue(for: characteristic)
        }
    }
    
    func writeValue(_ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType) async throws  {
        try await self.writeCharacteristicValueStorage.perform(withKey: characteristic.uuid) { [weak self] in
            guard let self = self else { return }
            
            self.cbPeripheral.writeValue(data, for: characteristic, type: type)
            
            guard type == .withoutResponse else {
                return
            }
            
            self.cbPeripheralDelegate.peripheral?(self.cbPeripheral, didWriteValueFor: characteristic, error: nil)
        }
    }
    
    func discoverDescriptors(for characteristic: CBCharacteristic) async throws {
        try await self.discoverDescriptorsStorage.perform(withKey: characteristic.uuid) { [weak self] in
            self?.cbPeripheral.discoverDescriptors(for: characteristic)
        }
    }
    
    func readValue(for descriptor: CBDescriptor) async throws {
        try await self.readDescriptorValueStorage.perform(withKey: descriptor.uuid) { [weak self] in
            self?.cbPeripheral.readValue(for: descriptor)
        }
    }
    
    func writeValue(_ data: Data, for descriptor: CBDescriptor) async throws {
        try await self.writeDescriptorValueStorage.perform(withKey: descriptor.uuid) { [weak self] in
            self?.cbPeripheral.writeValue(data, for: descriptor)
        }
    }
}

// MARK: CBPeripheralDelegate

extension Peripheral.DelegateWrapper: CBPeripheralDelegate {
    private static var logger: Logger = {
        Peripheral.logger
    }()
    
    func peripheral(_ cbPeripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: RSSI, error: error)
                try await self.peripheral?.readRSSIStorage.resume(result)
            } catch {
                Self.logger.error("Received ReadRSSI response without a continuation")
            }
        }
    }
    
    func peripheral(_ cbPeripheral: CBPeripheral, didDiscoverServices error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.peripheral?.discoverServiceStorage.resume(result)
            } catch {
                Self.logger.warning("Received DiscoverServices response without a continuation")
            }
        }
    }
    
    func peripheral(_ cbPeripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.peripheral?.discoverIncludedServicesStorage.resumeContinuation(
                    result, withKey: service.uuid
                )
            } catch {
                Self.logger.warning("Received DiscoverIncludedServices response without a continuation")
            }
        }
    }
    
    func peripheral(_ cbPeripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.peripheral?.discoverCharacteristicsStorage.resumeContinuation(result, withKey: service.uuid)
            } catch {
                Self.logger.warning("Received DiscoverCharacteristics result without a continuation")
            }
        }
    }
    
    func peripheral(_ cbPeripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.peripheral?.readCharacteristicValueStorage.resumeContinuation(
                    result, withKey: characteristic.uuid
                )
            } catch {
                guard !characteristic.isNotifying else {
                    return
                }
                Self.logger.warning("Received UpdateValue result for characteristic without a continuation")
            }
            
            guard characteristic.isNotifying else {
                return
            }
            self.peripheral?.characteristicValueUpdatedSubject.send(
                CharacteristicValueUpdatedEventData(characteristic: characteristic)
            )
        }
    }
    
    func peripheral(_ cbPeripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.peripheral?.writeCharacteristicValueStorage.resumeContinuation(
                    result, withKey: characteristic.uuid
                )
            } catch {
                Self.logger.warning("Received WriteValue result for characteristic without a continuation")
            }
        }
    }
    
    func peripheral(
        _ cbPeripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.peripheral?.setNotifyValueStorage.resumeContinuation(
                    result, withKey: characteristic.uuid
                )
            } catch {
                Self.logger.warning("Received UpdateNotificationState result without a continuation")
            }
        }
    }
    
    func peripheral(
        _ cbPeripheral: CBPeripheral,
        didDiscoverDescriptorsFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.peripheral?.discoverDescriptorsStorage.resumeContinuation(result, withKey: characteristic.uuid)
            } catch {
                Self.logger.warning("Received DiscoverDescriptors result without a continuation")
            }
        }
    }
    
    func peripheral(_ cbPeripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.peripheral?.readDescriptorValueStorage.resumeContinuation(result, withKey: descriptor.uuid)
            } catch {
                Self.logger.warning("Received UpdateValue result for descriptor without a continuation")
            }
        }
    }
    
    func peripheral(_ cbPeripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.peripheral?.writeDescriptorValueStorage.resumeContinuation(
                    result, withKey: descriptor.uuid
                )
            } catch {
                Self.logger.warning("Received WriteValue result for descriptor without a continuation")
            }
        }
    }
    
    func peripheral(_ cbPeripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.peripheral?.openL2CAPChannelStorage.resume(result)
            } catch {
                Self.logger.warning("Received OpenChannel result without a continuation")
            }
        }
    }
}
