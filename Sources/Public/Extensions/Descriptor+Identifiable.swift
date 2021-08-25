import Foundation
import CoreBluetooth

extension Descriptor: Identifiable {
    public typealias ID = CBUUID
    
    public var id: CBUUID {
        self.cbDescriptor.uuid
    }
}
