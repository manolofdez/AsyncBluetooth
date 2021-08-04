import Foundation
import CoreBluetooth

public struct Peripheral {
    private let cbPeripheral: CBPeripheral
    
    init(_ cbPeripheral: CBPeripheral) {
        self.cbPeripheral = cbPeripheral
    }
}

extension Peripheral: PeripheralType {
    public var name: String? {
        self.cbPeripheral.name
    }
}
