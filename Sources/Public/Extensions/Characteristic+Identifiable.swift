import Foundation
import CoreBluetooth

extension Characteristic: Identifiable {
    public typealias ID = CBUUID
    
    public var id: CBUUID {
        self.cbCharacteristic.uuid
    }
}
