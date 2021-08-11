import Foundation
import CoreBluetooth

/// A wrapper around `CBPeripheral`, used to interact with a remote peripheral.
public struct Peripheral {
    let cbPeripheral: CBPeripheral
    
    var name: String? {
        self.cbPeripheral.name
    }
    
    var identifier: UUID {
        self.cbPeripheral.identifier
    }
    
    init(_ cbPeripheral: CBPeripheral) {
        self.cbPeripheral = cbPeripheral
    }
}
