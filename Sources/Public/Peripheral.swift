import Foundation
import CoreBluetooth

/// A wrapper around `CBPeripheral`, used to interact with a remote peripheral.
public struct Peripheral {
    let cbPeripheral: CBPeripheral
    
    var name: String? {
        self.cbPeripheral.name
    }
    
    var identifier: UUID {
        self.cbPeripheral.identifier
    }
    
    private lazy var cbPeripheralDelegate: CBPeripheralDelegate = {
        CBPeripheralDelegateWrapper(
            onDidReadRSSI: { rssi, error in },
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
    
//    func readRSSI() {}
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
}
