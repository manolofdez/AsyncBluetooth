import Foundation
import CoreBluetooth

/// Provides callbacks for `CBPeripheralDelegate` functions.
class CBPeripheralDelegateWrapper: NSObject {
    private let onDidReadRSSI: CBCallback<NSNumber>
    private let onDidDiscoverServices: (_ error: Error?) -> Void
    private let onDidDiscoverIncludedServices: CBCallback<CBService>
    private let onDidDiscoverCharacteristics: CBCallback<CBService>
    private let onDidUpdateValueForCharacteristic: CBCallback<CBCharacteristic> // handles notifications too!
    private let onDidWriteValueForCharacteristic: CBCallback<CBCharacteristic>
    private let onDidUpdateNotificationState: CBCallback<CBCharacteristic>
    private let onDidDiscoverDescriptors: CBCallback<CBCharacteristic>
    private let onDidUpdateValueForDescriptor: CBCallback<CBDescriptor>
    private let onDidWriteValueForDescriptor: CBCallback<CBDescriptor>
    private let onDidOpenChannel: CBCallback<CBL2CAPChannel?>
    
    init(
        onDidReadRSSI: @escaping CBCallback<NSNumber>,
        onDidDiscoverServices: @escaping (_ error: Error?) -> Void,
        onDidDiscoverIncludedServices: @escaping CBCallback<CBService>,
        onDidDiscoverCharacteristics: @escaping CBCallback<CBService>,
        onDidUpdateValueForCharacteristic: @escaping CBCallback<CBCharacteristic>,
        onDidWriteValueForCharacteristic: @escaping CBCallback<CBCharacteristic>,
        onDidUpdateNotificationState: @escaping CBCallback<CBCharacteristic>,
        onDidDiscoverDescriptors: @escaping CBCallback<CBCharacteristic>,
        onDidUpdateValueForDescriptor: @escaping CBCallback<CBDescriptor>,
        onDidWriteValueForDescriptor: @escaping CBCallback<CBDescriptor>,
        onDidOpenChannel: @escaping CBCallback<CBL2CAPChannel?>
    ) {
        self.onDidReadRSSI = onDidReadRSSI
        self.onDidDiscoverServices = onDidDiscoverServices
        self.onDidDiscoverIncludedServices = onDidDiscoverIncludedServices
        self.onDidDiscoverCharacteristics = onDidDiscoverCharacteristics
        self.onDidUpdateValueForCharacteristic = onDidUpdateValueForCharacteristic
        self.onDidWriteValueForCharacteristic = onDidWriteValueForCharacteristic
        self.onDidUpdateNotificationState = onDidUpdateNotificationState
        self.onDidDiscoverDescriptors = onDidDiscoverDescriptors
        self.onDidUpdateValueForDescriptor = onDidUpdateValueForDescriptor
        self.onDidWriteValueForDescriptor = onDidWriteValueForDescriptor
        self.onDidOpenChannel = onDidOpenChannel

        super.init()
    }
}

extension CBPeripheralDelegateWrapper: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        self.onDidReadRSSI(RSSI, error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        self.onDidDiscoverServices(error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        self.onDidDiscoverIncludedServices(service, error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        self.onDidDiscoverCharacteristics(service, error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        self.onDidUpdateValueForCharacteristic(characteristic, error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        self.onDidWriteValueForCharacteristic(characteristic, error)
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        self.onDidUpdateNotificationState(characteristic, error)
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverDescriptorsFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        self.onDidDiscoverDescriptors(characteristic, error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        self.onDidUpdateValueForDescriptor(descriptor, error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        self.onDidWriteValueForDescriptor(descriptor, error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
        self.onDidOpenChannel(channel, error)
    }

}
