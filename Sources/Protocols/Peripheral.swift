//  Copyright (c) 2023 Manuel Fernandez-Peix Perez. All rights reserved.

import Foundation
import CoreBluetooth

public protocol Peripheral {
    associatedtype ServiceType: Service
    associatedtype CharacteristicType: Characteristic
    associatedtype DescriptorType: Descriptor
    
    /// The unique, persistent identifier associated with the peer.
    var identifier: UUID { get }
    
    /// The delegate object that will receive peripheral events.
    var delegate: CBPeripheralDelegate? { get set }

    /// The name of the peripheral.
    var name: String? { get }

    /// The most recently read RSSI, in decibels.
    @available(iOS, introduced: 5.0, deprecated: 8.0, message: "Use {@link peripheral:didReadRSSI:error:} instead.")
    var rssi: NSNumber? { get }

    /// The current connection state of the peripheral.
    var state: CBPeripheralState { get }

    /// A list of `CBService` objects that have been discovered on the peripheral.
    var services: [ServiceType]? { get }

    /// YES if the remote device has space to send a write without response. If this value is NO, the value will be set to YES after
    /// the current writes have been flushed, and `peripheralIsReadyToSendWriteWithoutResponse:` will be called.
    @available(iOS 11.0, *)
    var canSendWriteWithoutResponse: Bool { get }

    /// YES if the remote device has been authorized to receive data over ANCS (Apple Notification Service Center) protocol.
    /// If this value is NO, the value will be set to YES after a user authorization occurs and `didUpdateANCSAuthorizationForPeripheral:`
    /// will be called.
    @available(iOS 13.0, *)
    var ancsAuthorized: Bool { get }

    /// While connected, retrieves the current RSSI of the link.
    /// - SeeAlso: peripheral:didReadRSSI:error:
    func readRSSI()

    /// Discovers available service(s) on the peripheral.
    /// - Parameter serviceUUIDs: A list of `CBUUID` objects representing the service types to be discovered. If _nil_, all services
    /// will be discovered.
    /// - SeeAlso: peripheral:didDiscoverServices:
    func discoverServices(_ serviceUUIDs: [CBUUID]?)

    /// Discovers the specified included service(s) of _service_.
    /// - Parameter includedServiceUUIDs: A list of `CBUUID` objects representing the included service types to be discovered.
    ///                                   If _nil_, all of _service_ s included services will be discovered, which is considerably
    ///                                   slower and not recommended.
    /// - Parameter service: A GATT service.
    /// - SeeAlso: peripheral:didDiscoverIncludedServicesForService:error:
    func discoverIncludedServices(_ includedServiceUUIDs: [CBUUID]?, for service: ServiceType)

    /// Discovers the specified characteristic(s) of _service_.
    /// - Parameter characteristicUUIDs: A list of `CBUUID` objects representing the characteristic types to be discovered.
    ///                                  If _nil_, all characteristics of _service_ will be discovered.
    /// - Parameter service: A GATT service.
    /// - SeeAlso: peripheral:didDiscoverCharacteristicsForService:error:
    func discoverCharacteristics(_ characteristicUUIDs: [CBUUID]?, for service: ServiceType)
    
    /// Reads the characteristic value for _characteristic_.
    /// - Parameter characteristic: A GATT characteristic.
    /// - SeeAlso: peripheral:didUpdateValueForCharacteristic:error:
    func readValue(for characteristic: CharacteristicType)

    /// The maximum amount of data, in bytes, that can be sent to a characteristic in a single write type.
    /// - SeeAlso: writeValue:forCharacteristic:type:
    @available(iOS 9.0, *)
    func maximumWriteValueLength(for type: CBCharacteristicWriteType) -> Int

    /// Writes _value_ to _characteristic_'s characteristic value.
    ///
    /// If the `CBCharacteristicWriteWithResponse` type is specified, {`peripheral:didWriteValueForCharacteristic:error:`}
    /// is called with the result of the write request.
    /// If the `CBCharacteristicWriteWithoutResponse` type is specified, and `canSendWriteWithoutResponse`
    /// is false, the delivery of the data is best-effort and may not be guaranteed.
    /// - Parameter data: The value to write.
    /// - Parameter characteristic: The characteristic whose characteristic value will be written.
    /// - Parameter type: The type of write to be executed.
    /// - SeeAlso: peripheral:didWriteValueForCharacteristic:error:
    /// - SeeAlso: peripheralIsReadyToSendWriteWithoutResponse:
    /// - SeeAlso: canSendWriteWithoutResponse
    /// - SeeAlso: CBCharacteristicWriteType
    func writeValue(_ data: Data, for characteristic: CharacteristicType, type: CBCharacteristicWriteType)

    /// Enables or disables notifications/indications for the characteristic value of _characteristic_. If _characteristic_ allows both, n
    /// otifications will be used.
    ///
    /// When notifications/indications are enabled, updates to the characteristic value will be received via delegate method
    /// `peripheral:didUpdateValueForCharacteristic:error:`. Since it is the peripheral that chooses when to
    /// send an update, the application should be prepared to handle them as long as notifications/indications remain enabled.
    /// - Parameter enabled: Whether or not notifications/indications should be enabled.
    /// - Parameter characteristic: The characteristic containing the client characteristic configuration descriptor.
    /// - SeeAlso: peripheral:didUpdateNotificationStateForCharacteristic:error:
    /// - SeeAlso: CBConnectPeripheralOptionNotifyOnNotificationKey
    func setNotifyValue(_ enabled: Bool, for characteristic: CharacteristicType)

    /// Discovers the characteristic descriptor(s) of _characteristic_.
    /// - Parameter characteristic: A GATT characteristic.
    /// - SeeAlso: peripheral:didDiscoverDescriptorsForCharacteristic:error:
    func discoverDescriptors(for characteristic: CharacteristicType)

    /// Reads the value of _descriptor_.
    /// - Parameter descriptor: A GATT characteristic descriptor.
    /// - SeeAlso: peripheral:didUpdateValueForDescriptor:error:
    func readValue(for descriptor: DescriptorType)

    /// Writes _data_ to _descriptor_'s value. Client characteristic configuration descriptors cannot be written using
    /// this method, and should instead use `setNotifyValue:forCharacteristic:`.
    /// - Parameter data: The value to write.
    /// - Parameter descriptor: A GATT characteristic descriptor.
    /// - SeeAlso: peripheral:didWriteValueForCharacteristic:error:
    func writeValue(_ data: Data, for descriptor: DescriptorType)

    /// Attempt to open an L2CAP channel to the peripheral using the supplied PSM.
    /// - Parameter PSM: The PSM of the channel to open
    /// - SeeAlso: peripheral:didWriteValueForCharacteristic:error:
    @available(iOS 11.0, *)
    func openL2CAPChannel(_ PSM: CBL2CAPPSM)
}
