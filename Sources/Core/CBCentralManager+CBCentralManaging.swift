import Foundation
import CoreBluetooth

extension CBCentralManager: CBCentralManaging {
    func connect(_ peripheral: Peripheral, options: [String : Any]? = nil) {
        self.connect(peripheral.cbPeripheral, options: options)
    }
}
