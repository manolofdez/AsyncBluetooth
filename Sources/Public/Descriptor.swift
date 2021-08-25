import Foundation
import CoreBluetooth

public struct Descriptor {
    let cbDescriptor: CBDescriptor
    
    init(_ cbDescriptor: CBDescriptor) {
        self.cbDescriptor = cbDescriptor
    }
    
    public var value: Any? {
        self.cbDescriptor.value
    }
}
