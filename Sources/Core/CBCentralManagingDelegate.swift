import Foundation
import CoreBluetooth

class CBCentralManagingDelegate: NSObject {
    let onDidUpdateState: () -> Void
    let onDidDiscoverPeripheral: (PeripheralScanData) -> Void
    
    init(
        onDidUpdateState: @escaping () -> Void,
        onDidDiscoverPeripheral: @escaping (PeripheralScanData) -> Void
    ) {
        self.onDidUpdateState = onDidUpdateState
        self.onDidDiscoverPeripheral = onDidDiscoverPeripheral
    }
}

extension CBCentralManagingDelegate: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.onDidUpdateState()
    }
    
    // Optional
    
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
    
//    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {}
    
//    func centralManager(
//        _ central: CBCentralManager,
//        didFailToConnect peripheral: CBPeripheral,
//        error: Error?
//    ) {}
    
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
