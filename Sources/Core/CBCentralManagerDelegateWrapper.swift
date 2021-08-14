import Foundation
import CoreBluetooth

/// Provides callbacks for `CBCentralManagerDelegate` functions.
class CBCentralManagerDelegateWrapper: NSObject {
    private let onDidUpdateState: () -> Void
    private let onDidDiscoverPeripheral: (PeripheralScanData) -> Void
    private let onDidConnect: (CBPeripheral) -> Void
    private let onDidFailToConnect: (CBPeripheral, Error?) -> Void
    private let onDidDisconnectPeripheral: (CBPeripheral, Error?) -> Void
    
    init(
        onDidUpdateState: @escaping () -> Void,
        onDidDiscoverPeripheral: @escaping (PeripheralScanData) -> Void,
        onDidConnect: @escaping (CBPeripheral) -> Void,
        onDidFailToConnect: @escaping (CBPeripheral, Error?) -> Void,
        onDidDisconnectPeripheral: @escaping (CBPeripheral, Error?) -> Void
    ) {
        self.onDidUpdateState = onDidUpdateState
        self.onDidDiscoverPeripheral = onDidDiscoverPeripheral
        self.onDidConnect = onDidConnect
        self.onDidFailToConnect = onDidFailToConnect
        self.onDidDisconnectPeripheral = onDidDisconnectPeripheral
    }
}

extension CBCentralManagerDelegateWrapper: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.onDidUpdateState()
    }
    
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
        self.onDidConnect(peripheral)
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        self.onDidFailToConnect(peripheral, error)
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        self.onDidDisconnectPeripheral(peripheral, error)
    }
}
