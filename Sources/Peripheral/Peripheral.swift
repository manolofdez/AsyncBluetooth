//  Copyright (c) 2021 Manuel Fernandez-Peix Perez. All rights reserved.

import Foundation
@preconcurrency import CoreBluetooth
@preconcurrency import Combine
import os.log

/// A remote peripheral device.
/// - This class acts as a wrapper around `CBPeripheral`.
public final class Peripheral: Sendable {
        
    private static var logger: Logger {
        Logging.logger(for: "peripheral")
    }
    
    /// Publishes characteristics that are notifying of value changes.
    public var characteristicValueUpdatedPublisher: AnyPublisher<Characteristic, Never> {
        get async {
            await self.context.characteristicValueUpdatedSubject.eraseToAnyPublisher()
        }
    }
    
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
        #if os(iOS)
        self.cbPeripheral.ancsAuthorized
        #else
        false
        #endif
    }
    
    public let cbPeripheral: CBPeripheral
    
    private var context: PeripheralContext {
        cbPeripheralDelegate.context
    }
    
    /// The delegate object that will receive `cbPeripheral` callbacks.
    /// - Note: We need to hold on to it because `cbPeripheral` has a weak reference to it.
    private let cbPeripheralDelegate: PeripheralDelegate
    
    public init(_ cbPeripheral: CBPeripheral) {
        self.cbPeripheral = cbPeripheral
        
        // By reusing the cbPeripheralDelegate and context, we guarantee that we will enqueue calls to the peripheral
        // using the same context, and that won't lose any callbacks from the CBPeripheralDelegate.
        // This is important because we can create multiple Peripherals for a single cbPeripheral.
        if let cbPeripheralDelegate = cbPeripheral.delegate as? PeripheralDelegate {
            self.cbPeripheralDelegate = cbPeripheralDelegate
            return
        }
        
        if cbPeripheral.delegate != nil {
            Self.logger.warning("Replacing delegate for peripheral \(cbPeripheral.identifier) can cause problems.")
        }
        
        self.cbPeripheralDelegate = PeripheralDelegate()
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
    public func openL2CAPChannel(_ PSM: CBL2CAPPSM) async throws -> CBL2CAPChannel? {
        try await self.context.openL2CAPChannelExecutor.enqueue { [weak self] in
            self?.cbPeripheral.openL2CAPChannel(PSM)
        }
    }
    
    /// Cancels all pending operations, and stops awaiting for any responses.
    public func cancelAllOperations() async throws {
        try await self.context.flush(error: BluetoothError.operationCancelled)
    }
    
    // MARK: Services
    
    /// Discovers the specified services of the peripheral.
    public func discoverServices(_ serviceUUIDs: [CBUUID]?) async throws {
        try await self.context.discoverServiceExecutor.enqueue { [weak self] in
            self?.cbPeripheral.discoverServices(serviceUUIDs)
        }
    }
    
    /// Discovers the specified included services of a previously-discovered service.
    public func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: Service) async throws {
        try await self.context.discoverIncludedServicesExecutor.enqueue(withKey: service.uuid) { [weak self] in
            self?.cbPeripheral.discoverIncludedServices(includedServiceUUIDs, for: service.cbService)
        }
    }
    
    // MARK: Characteristics
    
    /// The maximum amount of data, in bytes, you can send to a characteristic in a single write type.
    public func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int {
        self.cbPeripheral.maximumWriteValueLength(for: type)
    }
    
    /// Sets notifications or indications for the value of a specified characteristic.
    public func setNotifyValue(_ enabled: Bool, for characteristic: Characteristic) async throws {
        try await self.context.setNotifyValueExecutor.enqueue(withKey: characteristic.uuid) { [weak self] in
            self?.cbPeripheral.setNotifyValue(enabled, for: characteristic.cbCharacteristic)
        }
    }
    
    /// Discovers the specified characteristics of a service.
    public func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: Service) async throws {
        try await self.context.discoverCharacteristicsExecutor.enqueue(withKey: service.uuid) { [weak self] in
            self?.cbPeripheral.discoverCharacteristics(characteristicUUIDs, for: service.cbService)
        }

    }
    
    /// Retrieves the value of a specified characteristic.
    public func readValue(for characteristic: Characteristic) async throws {
        try await self.context.readCharacteristicValueExecutor.enqueue(withKey: characteristic.uuid) { [weak self] in
            self?.cbPeripheral.readValue(for: characteristic.cbCharacteristic)
        }
    }
    
    /// Writes the value of a characteristic.
    public func writeValue(_ data: Data, for characteristic: Characteristic, type: CBCharacteristicWriteType) async throws {
        try await self.context.writeCharacteristicValueExecutor.enqueue(withKey: characteristic.uuid) { [weak self] in
            guard let self = self else { return }
            
            self.cbPeripheral.writeValue(data, for: characteristic.cbCharacteristic, type: type)
            
            guard type == .withoutResponse else {
                return
            }
            
            self.cbPeripheralDelegate.peripheral(self.cbPeripheral, didWriteValueFor: characteristic.cbCharacteristic, error: nil)
        }
    }
    
    // MARK: Descriptors
    
    /// Discovers the descriptors of a characteristic.
    public func discoverDescriptors(for characteristic: Characteristic) async throws {
        try await self.context.discoverDescriptorsExecutor.enqueue(withKey: characteristic.uuid) { [weak self] in
            self?.cbPeripheral.discoverDescriptors(for: characteristic.cbCharacteristic)
        }
    }
    
    /// Retrieves the value of a specified characteristic descriptor.
    public func readValue(for descriptor: Descriptor) async throws {
        try await self.context.readDescriptorValueExecutor.enqueue(withKey: descriptor.uuid) { [weak self] in
            self?.cbPeripheral.readValue(for: descriptor.cbDescriptor)
        }
    }
    
    /// Writes the value of a characteristic descriptor.
    public func writeValue(_ data: Data, for descriptor: Descriptor) async throws {
        try await self.context.writeDescriptorValueExecutor.enqueue(withKey: descriptor.uuid) { [weak self] in
            self?.cbPeripheral.writeValue(data, for: descriptor.cbDescriptor)
        }
    }
}
