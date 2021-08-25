import Foundation
import CoreBluetooth

public struct Characteristic {
    let cbCharacteristic: CBCharacteristic
    
    init(_ cbCharacteristic: CBCharacteristic) {
        self.cbCharacteristic = cbCharacteristic
    }
    
    public var properties: CBCharacteristicProperties {
        self.cbCharacteristic.properties
    }
    
    public var value: Data? {
        self.cbCharacteristic.value
    }

    public var descriptors: [Descriptor]? {
        self.cbCharacteristic.descriptors?.map { Descriptor($0) }
    }

    public var isNotifying: Bool {
        self.cbCharacteristic.isNotifying
    }
}
