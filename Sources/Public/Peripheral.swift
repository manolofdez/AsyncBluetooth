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
    
    private var readRSSIContinuation = CheckedContinuationStorage<NSNumber, Error>()
    
    private lazy var cbPeripheralDelegate: CBPeripheralDelegate = {
        CBPeripheralDelegateWrapper(
            onDidReadRSSI: { [weak self] rssi, error in
                self?.onDidReadRSSI(rssi: rssi, error: error)
            },
            onDidDiscoverServices: { error in },
            onDidDiscoverIncludedServices: { service, error in },
            onDidDiscoverCharacteristics: { service, error in },
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
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<NSNumber, Error>) in
            Task {
                do {
                    try await self.readRSSIContinuation.setContinuation(continuation)
                } catch {
                    continuation.resume(throwing: error)
                    return
                }
                self.cbPeripheral.readRSSI()
            }
        }
    }
    
//    func discoverServices(_ serviceUUIDs: [CBUUID]?) {}
//    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: Service) {}
//    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: Service) {}
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
                try await self.readRSSIContinuation.resume(result)
            } catch {
                Self.logger.error("Received RSSI value without a continuation")
            }
        }
    }
}
