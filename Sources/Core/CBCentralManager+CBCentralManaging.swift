import Foundation
import CoreBluetooth

extension CBCentralManager: CBCentralManaging {
    func connect(_ peripheral: Peripheral, options: [String : Any]? = nil) {
        self.connect(peripheral.cbPeripheral, options: options)
    }
    
    func cancelPeripheralConnection(_ peripheral: Peripheral) {
        self.cancelPeripheralConnection(peripheral.cbPeripheral)
    }
    
    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [Peripheral] {
        self.retrievePeripherals(withIdentifiers: identifiers).map { Peripheral($0) }
    }
    
    func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [Peripheral] {
        self.retrieveConnectedPeripherals(withServices: serviceUUIDs).map { Peripheral($0) }
    }
}
