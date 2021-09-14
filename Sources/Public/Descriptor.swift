import Foundation
import CoreBluetooth

/// An object that provides further information about a remote peripheral’s characteristic.
/// - This class acts as a wrapper for `CBDescriptor`.
public struct Descriptor {
    let cbDescriptor: CBDescriptor
    
    init(_ cbDescriptor: CBDescriptor) {
        self.cbDescriptor = cbDescriptor
    }
    
    /// The Bluetooth-specific UUID of the descriptor.
    public var id: CBUUID {
        self.cbDescriptor.uuid
    }
    
    public var value: Any? {
        self.cbDescriptor.value
    }
}
