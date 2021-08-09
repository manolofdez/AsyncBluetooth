import Foundation
import CoreBluetooth
@testable import AsyncBluetooth

class CBCentralManagerMock: CBCentralManaging {
    
    weak var delegate: CBCentralManagerDelegate?
    
    var managingDelegate: CBCentralManagingDelegate {
        guard let delegate = self.delegate as? CBCentralManagingDelegate else {
            fatalError("Delegate should be an instance of CBCentralManagingDelegate")
        }
        return delegate
    }
    
    var isScanning: Bool {
        self.timer != nil
    }
    
    var state: CBManagerState = .poweredOn {
        didSet {
            self.managingDelegate.onDidUpdateState()
        }
    }
    
    private var timer: Timer?
    private var peripheralsFound = 0
    
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]?) {
        guard timer == nil else {
            fatalError()
        }
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                
                self.peripheralsFound += 1
                
                let peripheralScanData = PeripheralScanData(
                    peripheral: PeripheralMock(name: nil),
                    advertisementData: [:],
                    rssi: NSNumber(value: self.peripheralsFound)
                )
                self.managingDelegate.onDidDiscoverPeripheral(peripheralScanData)
            }
        }
    }
    
    func stopScan() {
        self.timer?.invalidate()
        self.timer = nil
    }
    
}

