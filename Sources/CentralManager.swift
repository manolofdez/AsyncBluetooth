//
//  File.swift
//  
//
//  Created by Manuel Fernandez on 8/2/21.
//

import Foundation
import CoreBluetooth

public struct CentralManager {
    let cbCentralManager: CBCentralManager
    let cbCentralManagerDelegate: CBCentralManagerDelegate
    
    init(dispatchQueue: DispatchQueue? = nil, options: [String: Any]? = nil) {
        self.cbCentralManagerDelegate = CentralManagerDelegate()
        self.cbCentralManager = CBCentralManager(
            delegate: self.cbCentralManagerDelegate,
            queue: dispatchQueue,
            options: options
        )
    }
    
    // To Implement
    
//    open var isScanning: Bool { get }
//    open class func supports(_ features: CBCentralManager.Feature) -> Bool
//    open func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBPeripheral]
//    open func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [CBPeripheral]
//    open func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]? = nil)
//    open func stopScan()
//    open func connect(_ peripheral: CBPeripheral, options: [String : Any]? = nil)
//    open func cancelPeripheralConnection(_ peripheral: CBPeripheral)
//    open func registerForConnectionEvents(options: [CBConnectionEventMatchingOption : Any]? = nil)
}
