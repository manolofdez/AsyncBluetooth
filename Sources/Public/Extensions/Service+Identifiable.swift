import Foundation
import CoreBluetooth

extension Service: Identifiable {
    public typealias ID = CBUUID
    
    public var id: CBUUID {
        self.cbService.uuid
    }
}
