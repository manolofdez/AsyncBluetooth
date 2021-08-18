import Foundation
import CoreBluetooth
import Combine
import os.log

/// A wrapper around `CBPeripheral`, used to interact with a remote peripheral.
public class Peripheral {
        
    private static let logger = Logger(
        subsystem: Bundle(for: Peripheral.self).bundleIdentifier ?? "",
        category: "peripheral"
    )
    
    public lazy var characteristicValueUpdatedPublisher: AnyPublisher<CharacteristicValueUpdatedEventData, Never> = {
        self.characteristicValueUpdatedSubject.eraseToAnyPublisher()
    }()
    
    let cbPeripheral: CBPeripheral
    
    var name: String? {
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
        CBPeripheralDelegateWrapper(
            onDidReadRSSI: { [weak self] rssi, error in
                self?.onDidReadRSSI(rssi: rssi, error: error)
            },
            onDidDiscoverServices: { [weak self] error in
                self?.onDidDiscoverServices(error: error)
            },
            onDidDiscoverIncludedServices: { [weak self] service, error in
                self?.onDidDiscoverIncludedServices(service: service, error: error)
            },
            onDidDiscoverCharacteristics: { [weak self] service, error in
                self?.onDidDiscoverCharacteristics(service: service, error: error)
            },
            onDidUpdateValueForCharacteristic: { [weak self] characteristic, error in
                self?.onDidUpdateValueForCharacteristic(characteristic, error: error)
            },
            onDidWriteValueForCharacteristic: { [weak self] characteristic, error in
                self?.onDidWriteValueForCharacteristic(characteristic, error: error)
            },
            onDidUpdateNotificationState: { [weak self] characteristic, error in
                self?.onDidUpdateNotificationState(characteristic: characteristic, error: error)
            },
            onDidDiscoverDescriptors: { [weak self] characteristic, error in
                self?.onDidDiscoverDescriptors(characteristic: characteristic, error: error)
            },
            onDidUpdateValueForDescriptor: { [weak self] descriptor, error in
                self?.onDidUpdateValueForDescriptor(descriptor, error: error)
            },
            onDidWriteValueForDescriptor: { [weak self] descriptor, error in
                self?.onDidWriteValueForDescriptor(descriptor, error: error)
            },
            onDidOpenChannel: { [weak self] channel, error in
                self?.onDidOpenChannel(channel, error: error)
            }
        )
    }()
    
    init(_ cbPeripheral: CBPeripheral) {
        self.cbPeripheral = cbPeripheral
    }
    
    public func readRSSI() async throws -> NSNumber {
        try await self.readRSSIStorage.perform { [weak self] in
            self?.cbPeripheral.readRSSI()
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
    
    public func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int {
        self.cbPeripheral.maximumWriteValueLength(for: type)
    }
    
    func writeValue(_ data: Data, for characteristic: CBCharacteristic, type: CBCharacteristicWriteType) async throws  {
        try await self.writeCharacteristicValueStorage.perform(withKey: characteristic.uuid) { [weak self] in
            self?.cbPeripheral.writeValue(data, for: characteristic, type: type)
            
            guard type == .withoutResponse else {
                return
            }
            
            self?.onDidWriteValueForCharacteristic(characteristic, error: nil)
        }
    }
    
    public func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic) async throws {
        try await self.setNotifyValueStorage.perform(withKey: characteristic.uuid) { [weak self] in
            self?.cbPeripheral.setNotifyValue(enabled, for: characteristic)
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

    @available(iOS 11.0, *)
    public func openL2CAPChannel(_ PSM: CBL2CAPPSM) async throws {
        try await self.openL2CAPChannelStorage.perform { [weak self] in 
            self?.cbPeripheral.openL2CAPChannel(PSM)
        }
    }
    
    // MARK: CBPeripheralDelegate Callbacks
    
    private func onDidReadRSSI(rssi: NSNumber, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: rssi, error: error)
                try await self.readRSSIStorage.resume(result)
            } catch {
                Self.logger.error("Received ReadRSSI response without a continuation")
            }
        }
    }
    
    private func onDidDiscoverServices(error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.discoverServiceStorage.resume(result)
            } catch {
                Self.logger.warning("Received DiscoverServices response without a continuation")
            }
        }
    }
    
    private func onDidDiscoverIncludedServices(service: CBService, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.discoverIncludedServicesStorage.resumeContinuation(result, withKey: service.uuid)
            } catch {
                Self.logger.warning("Received DiscoverIncludedServices response without a continuation")
            }
        }
    }
    
    private func onDidDiscoverCharacteristics(service: CBService, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.discoverCharacteristicsStorage.resumeContinuation(result, withKey: service.uuid)
            } catch {
                Self.logger.warning("Received DiscoverCharacteristics result without a continuation")
            }
        }
    }
    
    private func onDidUpdateValueForCharacteristic(_ characteristic: CBCharacteristic, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.readCharacteristicValueStorage.resumeContinuation(result, withKey: characteristic.uuid)
            } catch {
                guard !characteristic.isNotifying else {
                    return
                }
                Self.logger.warning("Received UpdateValue result for characteristic without a continuation")
            }
            
            guard characteristic.isNotifying else {
                return
            }
            self.characteristicValueUpdatedSubject.send(
                CharacteristicValueUpdatedEventData(characteristic: characteristic)
            )
        }
    }
    
    private func onDidWriteValueForCharacteristic(_ characteristic: CBCharacteristic, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.writeCharacteristicValueStorage.resumeContinuation(result, withKey: characteristic.uuid)
            } catch {
                Self.logger.warning("Received WriteValue result for characteristic without a continuation")
            }
        }
    }
    
    private func onDidUpdateNotificationState(characteristic: CBCharacteristic, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.setNotifyValueStorage.resumeContinuation(result, withKey: characteristic.uuid)
            } catch {
                Self.logger.warning("Received UpdateNotificationState result without a continuation")
            }
        }
    }
    
    private func onDidDiscoverDescriptors(characteristic: CBCharacteristic, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.discoverDescriptorsStorage.resumeContinuation(result, withKey: characteristic.uuid)
            } catch {
                Self.logger.warning("Received DiscoverDescriptors result without a continuation")
            }
        }
    }
    
    private func onDidUpdateValueForDescriptor(_ descriptor: CBDescriptor, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.readDescriptorValueStorage.resumeContinuation(result, withKey: descriptor.uuid)
            } catch {
                Self.logger.warning("Received UpdateValue result for descriptor without a continuation")
            }
        }
    }
    
    private func onDidWriteValueForDescriptor(_ descriptor: CBDescriptor, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.writeDescriptorValueStorage.resumeContinuation(result, withKey: descriptor.uuid)
            } catch {
                Self.logger.warning("Received WriteValue result for descriptor without a continuation")
            }
        }
    }
    
    private func onDidOpenChannel(_ channel: CBL2CAPChannel?, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.openL2CAPChannelStorage.resume(result)
            } catch {
                Self.logger.warning("Received OpenChannel result without a continuation")
            }
        }
    }
}
