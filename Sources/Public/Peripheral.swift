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
    
    public lazy var characteristicValueUpdatedPublisher: AnyPublisher<Characteristic, Never> = {
        self.characteristicValueUpdatedSubject.eraseToAnyPublisher()
    }()
    
    public var name: String? {
        self.cbPeripheral.name
    }
    
    public var discoveredServices: [Service]? {
        self.cbPeripheral.services?.map { Service($0) }
    }
    
    public var state: CBPeripheralState {
        self.cbPeripheral.state
    }
    
    public var ancsAuthorized: Bool {
        self.cbPeripheral.ancsAuthorized
    }
    
    let cbPeripheral: CBPeripheral
    
    private let characteristicValueUpdatedSubject = PassthroughSubject<Characteristic, Never>()
    
    private let readRSSIExecutor = AsyncSerialExecutor<NSNumber>()
    private let discoverServiceExecutor = AsyncSerialExecutor<Void>()
    private let discoverIncludedServicesExecutor = AsyncExecutorMap<CBUUID, Void>()
    private let discoverCharacteristicsExecutor = AsyncExecutorMap<CBUUID, Void>()
    private let readCharacteristicValueExecutor = AsyncExecutorMap<CBUUID, Void>()
    private let writeCharacteristicValueExecutor = AsyncExecutorMap<CBUUID, Void>()
    private let setNotifyValueExecutor = AsyncExecutorMap<CBUUID, Void>()
    private let discoverDescriptorsExecutor = AsyncExecutorMap<CBUUID, Void>()
    private let readDescriptorValueExecutor = AsyncExecutorMap<CBUUID, Void>()
    private let writeDescriptorValueExecutor = AsyncExecutorMap<CBUUID, Void>()
    private let openL2CAPChannelExecutor = AsyncSerialExecutor<Void>()
    
    private lazy var cbPeripheralDelegate: CBPeripheralDelegate = {
        DelegateWrapper(owner: self)
    }()
    
    init(_ cbPeripheral: CBPeripheral) {
        self.cbPeripheral = cbPeripheral
    }
    
    public func readRSSI() async throws -> NSNumber {
        try await self.readRSSIExecutor.enqueue { [weak self] in
            self?.cbPeripheral.readRSSI()
        }
    }
    
    @available(iOS 11.0, *)
    public func openL2CAPChannel(_ PSM: CBL2CAPPSM) async throws {
        try await self.openL2CAPChannelExecutor.enqueue { [weak self] in
            self?.cbPeripheral.openL2CAPChannel(PSM)
        }
    }
    
    // MARK: Public: Services
    
    public func discoverServices(_ serviceUUIDs: [CBUUID]?) async throws {
        try await self.discoverServiceExecutor.enqueue { [weak self] in
            self?.cbPeripheral.discoverServices(serviceUUIDs)
        }
    }
    
    public func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: Service) async throws {
        try await self.discoverIncludedServices(includedServiceUUIDs, for: service.cbService)
    }
    
    // MARK: Public: Characteristics
    
    public func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int {
        self.cbPeripheral.maximumWriteValueLength(for: type)
    }
    
    public func setNotifyValue(_ enabled: Bool, for characteristic: Characteristic) async throws {
        try await self.setNotifyValue(enabled, for: characteristic.cbCharacteristic)
    }
    
    public func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: Service) async throws {
        try await self.discoverCharacteristics(characteristicUUIDs, for: service.cbService)
    }
    
    public func readValue(for characteristic: Characteristic) async throws {
        try await self.readValue(for: characteristic.cbCharacteristic)
    }
    
    public func writeValue(_ data: Data, for characteristic: Characteristic, type: CBCharacteristicWriteType) async throws {
        try await self.writeValue(data, for: characteristic.cbCharacteristic, type: type)
    }
    
    // MARK: Public Descriptors
    
    public func discoverDescriptors(for characteristic: Characteristic) async throws {
        try await self.discoverDescriptors(for: characteristic.cbCharacteristic)
    }
    
    public func readValue(for descriptor: Descriptor) async throws {
        try await self.readValue(for: descriptor.cbDescriptor)
    }
    
    public func writeValue(_ data: Data, for descriptor: Descriptor) async throws {
        try await self.writeValue(data, for: descriptor)
    }
    
    // MARK: Internal: Services
    
    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: CBService) async throws {
        try await self.discoverIncludedServicesExecutor.enqueue(withKey: service.uuid) { [weak self] in
            self?.cbPeripheral.discoverIncludedServices(includedServiceUUIDs, for: service)
        }
    }
    
    // MARK: Internal: Characteristics
    
    func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic) async throws {
        try await self.setNotifyValueExecutor.enqueue(withKey: characteristic.uuid) { [weak self] in
            self?.cbPeripheral.setNotifyValue(enabled, for: characteristic)
        }
    }
    
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService) async throws {
        try await self.discoverCharacteristicsExecutor.enqueue(withKey: service.uuid) { [weak self] in
            self?.cbPeripheral.discoverCharacteristics(characteristicUUIDs, for: service)
        }
    }
    
    func readValue(for characteristic: CBCharacteristic) async throws {
        try await self.readCharacteristicValueExecutor.enqueue(withKey: characteristic.uuid) { [weak self] in
            self?.cbPeripheral.readValue(for: characteristic)
        }
    }
    
    func writeValue(
        _ data: Data,
        for characteristic: CBCharacteristic,
        type: CBCharacteristicWriteType
    ) async throws {
        try await self.writeCharacteristicValueExecutor.enqueue(withKey: characteristic.uuid) { [weak self] in
            guard let self = self else { return }
            
            self.cbPeripheral.writeValue(data, for: characteristic, type: type)
            
            guard type == .withoutResponse else {
                return
            }
            
            self.cbPeripheralDelegate.peripheral?(self.cbPeripheral, didWriteValueFor: characteristic, error: nil)
        }
    }
    
    // MARK: Internal: Descriptors
    
    func discoverDescriptors(for characteristic: CBCharacteristic) async throws {
        try await self.discoverDescriptorsExecutor.enqueue(withKey: characteristic.uuid) { [weak self] in
            self?.cbPeripheral.discoverDescriptors(for: characteristic)
        }
    }
    
    func readValue(for descriptor: CBDescriptor) async throws {
        try await self.readDescriptorValueExecutor.enqueue(withKey: descriptor.uuid) { [weak self] in
            self?.cbPeripheral.readValue(for: descriptor)
        }
    }
    
    func writeValue(_ data: Data, for descriptor: CBDescriptor) async throws {
        try await self.writeDescriptorValueExecutor.enqueue(withKey: descriptor.uuid) { [weak self] in
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
                try await self.peripheral?.readRSSIExecutor.setWorkCompletedWithResult(result)
            } catch {
                Self.logger.error("Received ReadRSSI response without a continuation")
            }
        }
    }
    
    func peripheral(_ cbPeripheral: CBPeripheral, didDiscoverServices error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.peripheral?.discoverServiceExecutor.setWorkCompletedWithResult(result)
            } catch {
                Self.logger.warning("Received DiscoverServices response without a continuation")
            }
        }
    }
    
    func peripheral(_ cbPeripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.peripheral?.discoverIncludedServicesExecutor.setWorkCompletedForKey(
                    service.uuid, result: result
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
                try await self.peripheral?.discoverCharacteristicsExecutor.setWorkCompletedForKey(
                    service.uuid, result: result
                )
            } catch {
                Self.logger.warning("Received DiscoverCharacteristics result without a continuation")
            }
        }
    }
    
    func peripheral(_ cbPeripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.peripheral?.readCharacteristicValueExecutor.setWorkCompletedForKey(
                    characteristic.uuid, result: result
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
                Characteristic(characteristic)
            )
        }
    }
    
    func peripheral(_ cbPeripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.peripheral?.writeCharacteristicValueExecutor.setWorkCompletedForKey(
                    characteristic.uuid, result: result
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
                try await self.peripheral?.setNotifyValueExecutor.setWorkCompletedForKey(
                    characteristic.uuid, result: result
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
                try await self.peripheral?.discoverDescriptorsExecutor.setWorkCompletedForKey(
                    characteristic.uuid, result: result
                )
            } catch {
                Self.logger.warning("Received DiscoverDescriptors result without a continuation")
            }
        }
    }
    
    func peripheral(_ cbPeripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.peripheral?.readDescriptorValueExecutor.setWorkCompletedForKey(
                    descriptor.uuid, result: result
                )
            } catch {
                Self.logger.warning("Received UpdateValue result for descriptor without a continuation")
            }
        }
    }
    
    func peripheral(_ cbPeripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.peripheral?.writeDescriptorValueExecutor.setWorkCompletedForKey(
                    descriptor.uuid, result: result
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
                try await self.peripheral?.openL2CAPChannelExecutor.setWorkCompletedWithResult(result)
            } catch {
                Self.logger.warning("Received OpenChannel result without a continuation")
            }
        }
    }
}
