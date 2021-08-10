import Foundation
import CoreBluetooth

/// Provides callbacks for `CBCentralManagerDelegate` functions.
class CBCentralManagerCallbackProvider: NSObject {
    let onDidUpdateState: () -> Void
    let onDidDiscoverPeripheral: (PeripheralScanData) -> Void
    let onDidConnect: () -> Void
    let onDidFailToConnect: (Error?) -> Void
    
    init(
        onDidUpdateState: @escaping () -> Void,
        onDidDiscoverPeripheral: @escaping (PeripheralScanData) -> Void,
        onDidConnect: @escaping () -> Void,
        onDidFailToConnect: @escaping (Error?) -> Void
    ) {
        self.onDidUpdateState = onDidUpdateState
        self.onDidDiscoverPeripheral = onDidDiscoverPeripheral
        self.onDidConnect = onDidConnect
        self.onDidFailToConnect = onDidFailToConnect
    }
}

extension CBCentralManagerCallbackProvider: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.onDidUpdateState()
    }
    
//    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {}
    
    func centralManager(
        _ central: CBCentralManager,
        didDiscover cbPeripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber
    ) {
        let peripheralScanData = PeripheralScanData(
            peripheral: Peripheral(cbPeripheral),
            advertisementData: advertisementData,
            rssi: RSSI
        )
        self.onDidDiscoverPeripheral(peripheralScanData)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.onDidConnect()
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        self.onDidFailToConnect(error)
    }
    
//    func centralManager(
//        _ central: CBCentralManager,
//        didDisconnectPeripheral peripheral: CBPeripheral,
//        error: Error?
//    ) {}
    
//    func centralManager(
//        _ central: CBCentralManager,
//        connectionEventDidOccur event: CBConnectionEvent,
//        for peripheral: CBPeripheral
//    ) {}
    
//    func centralManager(_ central: CBCentralManager, didUpdateANCSAuthorizationFor peripheral: CBPeripheral) {}
}
