import Foundation
import CoreBluetooth
import Combine
import os.log

/// A remote peripheral device.
/// - This class acts as a wrapper around `CBPeripheral`.
public class Peripheral {
    
    fileprivate class DelegateWrapper: NSObject {
        private let context: PeripheralContext
        
        init(context: PeripheralContext) {
            self.context = context
        }
    }
    
    private static let logger = Logger(
        subsystem: Bundle(for: Peripheral.self).bundleIdentifier ?? "",
        category: "peripheral"
    )
    
    /// Publishes characteristics that are notifying of value changes.
    public lazy var characteristicValueUpdatedPublisher: AnyPublisher<Characteristic, Never> = {
        self.context.characteristicValueUpdatedSubject.eraseToAnyPublisher()
    }()
    
    /// The UUID associated with the peripheral.
    public var identifier: UUID {
        self.cbPeripheral.identifier
    }
    
    public var name: String? {
        self.cbPeripheral.name
    }
    
    /// A list of a peripheral’s discovered services.
    public var discoveredServices: [Service]? {
        self.cbPeripheral.services?.map { Service($0) }
    }
    
    /// The connection state of the peripheral.
    public var state: CBPeripheralState {
        self.cbPeripheral.state
    }
    
    /// A Boolean value that indicates if the remote device has authorization to receive data over ANCS protocol.
    public var ancsAuthorized: Bool {
        self.cbPeripheral.ancsAuthorized
    }
    
    let cbPeripheral: CBPeripheral
    
    let context = PeripheralContext()

    private let cbPeripheralDelegate: DelegateWrapper
    
    init(_ cbPeripheral: CBPeripheral) {
        self.cbPeripheral = cbPeripheral
        self.cbPeripheralDelegate = DelegateWrapper(context: self.context)
        self.cbPeripheral.delegate = self.cbPeripheralDelegate
    }
    
    /// Retrieves the current RSSI value for the peripheral while connected to the central manager.
    public func readRSSI() async throws -> NSNumber {
        try await self.context.readRSSIExecutor.enqueue { [weak self] in
            self?.cbPeripheral.readRSSI()
        }
    }
    
    /// Attempts to open an L2CAP channel to the peripheral using the supplied Protocol/Service Multiplexer (PSM).
    @available(iOS 11.0, *)
    public func openL2CAPChannel(_ PSM: CBL2CAPPSM) async throws {
        try await self.context.openL2CAPChannelExecutor.enqueue { [weak self] in
            self?.cbPeripheral.openL2CAPChannel(PSM)
        }
    }
    
    // MARK: Public: Services
    
    /// Discovers the specified services of the peripheral.
    public func discoverServices(_ serviceUUIDs: [CBUUID]?) async throws {
        try await self.context.discoverServiceExecutor.enqueue { [weak self] in
            self?.cbPeripheral.discoverServices(serviceUUIDs)
        }
    }
    
    /// Discovers the specified included services of a previously-discovered service.
    public func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: Service) async throws {
        try await self.discoverIncludedServices(includedServiceUUIDs, for: service.cbService)
    }
    
    // MARK: Public: Characteristics
    
    /// The maximum amount of data, in bytes, you can send to a characteristic in a single write type.
    public func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int {
        self.cbPeripheral.maximumWriteValueLength(for: type)
    }
    
    /// Sets notifications or indications for the value of a specified characteristic.
    public func setNotifyValue(_ enabled: Bool, for characteristic: Characteristic) async throws {
        try await self.setNotifyValue(enabled, for: characteristic.cbCharacteristic)
    }
    
    /// Discovers the specified characteristics of a service.
    public func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: Service) async throws {
        try await self.discoverCharacteristics(characteristicUUIDs, for: service.cbService)
    }
    
    /// Retrieves the value of a specified characteristic.
    public func readValue(for characteristic: Characteristic) async throws {
        try await self.readValue(for: characteristic.cbCharacteristic)
    }
    
    /// Writes the value of a characteristic.
    public func writeValue(_ data: Data, for characteristic: Characteristic, type: CBCharacteristicWriteType) async throws {
        try await self.writeValue(data, for: characteristic.cbCharacteristic, type: type)
    }
    
    // MARK: Public Descriptors
    
    /// Discovers the descriptors of a characteristic.
    public func discoverDescriptors(for characteristic: Characteristic) async throws {
        try await self.discoverDescriptors(for: characteristic.cbCharacteristic)
    }
    
    /// Retrieves the value of a specified characteristic descriptor.
    public func readValue(for descriptor: Descriptor) async throws {
        try await self.readValue(for: descriptor.cbDescriptor)
    }
    
    /// Writes the value of a characteristic descriptor.
    public func writeValue(_ data: Data, for descriptor: Descriptor) async throws {
        try await self.writeValue(data, for: descriptor)
    }
    
    // MARK: Internal: Services
    
    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: CBService) async throws {
        try await self.context.discoverIncludedServicesExecutor.enqueue(withKey: service.uuid) { [weak self] in
            self?.cbPeripheral.discoverIncludedServices(includedServiceUUIDs, for: service)
        }
    }
    
    // MARK: Internal: Characteristics
    
    func setNotifyValue(_ enabled: Bool, for characteristic: CBCharacteristic) async throws {
        try await self.context.setNotifyValueExecutor.enqueue(withKey: characteristic.uuid) { [weak self] in
            self?.cbPeripheral.setNotifyValue(enabled, for: characteristic)
        }
    }
    
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: CBService) async throws {
        try await self.context.discoverCharacteristicsExecutor.enqueue(withKey: service.uuid) { [weak self] in
            self?.cbPeripheral.discoverCharacteristics(characteristicUUIDs, for: service)
        }
    }
    
    func readValue(for characteristic: CBCharacteristic) async throws {
        try await self.context.readCharacteristicValueExecutor.enqueue(withKey: characteristic.uuid) { [weak self] in
            self?.cbPeripheral.readValue(for: characteristic)
        }
    }
    
    func writeValue(
        _ data: Data,
        for characteristic: CBCharacteristic,
        type: CBCharacteristicWriteType
    ) async throws {
        try await self.context.writeCharacteristicValueExecutor.enqueue(withKey: characteristic.uuid) { [weak self] in
            guard let self = self else { return }
            
            self.cbPeripheral.writeValue(data, for: characteristic, type: type)
            
            guard type == .withoutResponse else {
                return
            }
            
            self.cbPeripheralDelegate.peripheral(self.cbPeripheral, didWriteValueFor: characteristic, error: nil)
        }
    }
    
    // MARK: Internal: Descriptors
    
    func discoverDescriptors(for characteristic: CBCharacteristic) async throws {
        try await self.context.discoverDescriptorsExecutor.enqueue(withKey: characteristic.uuid) { [weak self] in
            self?.cbPeripheral.discoverDescriptors(for: characteristic)
        }
    }
    
    func readValue(for descriptor: CBDescriptor) async throws {
        try await self.context.readDescriptorValueExecutor.enqueue(withKey: descriptor.uuid) { [weak self] in
            self?.cbPeripheral.readValue(for: descriptor)
        }
    }
    
    func writeValue(_ data: Data, for descriptor: CBDescriptor) async throws {
        try await self.context.writeDescriptorValueExecutor.enqueue(withKey: descriptor.uuid) { [weak self] in
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
                try await self.context.readRSSIExecutor.setWorkCompletedWithResult(result)
            } catch {
                Self.logger.error("Received ReadRSSI response without a continuation")
            }
        }
    }
    
    func peripheral(_ cbPeripheral: CBPeripheral, didDiscoverServices error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.context.discoverServiceExecutor.setWorkCompletedWithResult(result)
            } catch {
                Self.logger.warning("Received DiscoverServices response without a continuation")
            }
        }
    }
    
    func peripheral(_ cbPeripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.context.discoverIncludedServicesExecutor.setWorkCompletedForKey(
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
                try await self.context.discoverCharacteristicsExecutor.setWorkCompletedForKey(
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
                try await self.context.readCharacteristicValueExecutor.setWorkCompletedForKey(
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
            self.context.characteristicValueUpdatedSubject.send(
                Characteristic(characteristic)
            )
        }
    }
    
    func peripheral(_ cbPeripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.context.writeCharacteristicValueExecutor.setWorkCompletedForKey(
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
                try await self.context.setNotifyValueExecutor.setWorkCompletedForKey(
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
                try await self.context.discoverDescriptorsExecutor.setWorkCompletedForKey(
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
                try await self.context.readDescriptorValueExecutor.setWorkCompletedForKey(
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
                try await self.context.writeDescriptorValueExecutor.setWorkCompletedForKey(
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
                try await self.context.openL2CAPChannelExecutor.setWorkCompletedWithResult(result)
            } catch {
                Self.logger.warning("Received OpenChannel result without a continuation")
            }
        }
    }
}
