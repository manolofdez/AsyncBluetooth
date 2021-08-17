import Foundation
import CoreBluetooth
import os.log

/// A wrapper around `CBPeripheral`, used to interact with a remote peripheral.
public class Peripheral {
    
    private static let logger = Logger(
        subsystem: Bundle(for: Peripheral.self).bundleIdentifier ?? "",
        category: "peripheral"
    )
    
    let cbPeripheral: CBPeripheral
    
    var name: String? {
        self.cbPeripheral.name
    }
    
    var identifier: UUID {
        self.cbPeripheral.identifier
    }
    
    private let readRSSIStorage = CheckedContinuationStorage<NSNumber, Error>()
    private let discoverServiceStorage = CheckedContinuationStorage<Void, Error>()
    private let discoverIncludedServicesStorage = CheckedContinuationMapStorage<CBUUID, Void, Error>()
    private let discoverCharacteristicsStorage = CheckedContinuationMapStorage<CBUUID, Void, Error>()
    
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
            onDidUpdateValueForCharacteristic: { characteristic, error in },
            onDidWriteValueForCharacteristic: { characteristic, error in },
            onDidUpdateNotificationState: { characteristic, error in },
            onDidDiscoverDescriptors: { characteristic, error in },
            onDidUpdateValueForDescriptor: { descriptor, error in },
            onDidWriteValueForDescriptor: { descrioptor, error in },
            onPeripheralIsReadyToSendWriteWithoutResponse: {},
            onDidOpenChannel: { channel, error in }
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
//    func readValue(for characteristic: Characteristic) {}
//    func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int {}
//    func writeValue(_ data: Data, for characteristic: Characteristic, type: CBCharacteristicWriteType) {}
//    func setNotifyValue(_ enabled: Bool, for characteristic: Characteristic) {}
//    func discoverDescriptors(for characteristic: Characteristic) {}
//    func readValue(for descriptor: Descriptor) {}
//    func writeValue(_ data: Data, for descriptor: Descriptor) {}
//
//    @available(iOS 11.0, *)
//    func openL2CAPChannel(_ PSM: CBL2CAPPSM) {}
    
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
                try await self.discoverIncludedServicesStorage.resumeContinuation(
                    result, withKey: service.uuid
                )
            } catch {
                Self.logger.warning("Received DiscoverIncludedServices response without a continuation")
            }
        }
    }
    
    private func onDidDiscoverCharacteristics(service: CBService, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.discoverCharacteristicsStorage.resumeContinuation(
                    result, withKey: service.uuid
                )
            } catch {
                Self.logger.warning("Received DiscoverCharacteristics result without a continuation")
            }
        }
    }
}
