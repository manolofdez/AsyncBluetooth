//
//  File.swift
//  
//
//  Created by Manuel Fernandez on 8/2/21.
//

import Foundation
import CoreBluetooth

class CentralManagerDelegate: NSObject, CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {}
    
    // Optional
    
    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {}
    public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber
    ) {}
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {}
    public func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {}
    public func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {}
//    public func centralManager(
//        _ central: CBCentralManager,
//        connectionEventDidOccur event: CBConnectionEvent,
//        for peripheral: CBPeripheral
//    ) {}
//    public func centralManager(_ central: CBCentralManager, didUpdateANCSAuthorizationFor peripheral: CBPeripheral) {}
}
