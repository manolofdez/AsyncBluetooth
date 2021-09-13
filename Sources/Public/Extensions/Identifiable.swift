import Foundation
import CoreBluetooth

extension Peripheral: Identifiable {
    public typealias ID = UUID
    
    public var id: UUID {
        self.cbPeripheral.identifier
    }
}

extension Service: Identifiable {
    public typealias ID = CBUUID
    
    public var id: CBUUID {
        self.cbService.uuid
    }
}

extension Characteristic: Identifiable {
    public typealias ID = CBUUID
    
    public var id: CBUUID {
        self.cbCharacteristic.uuid
    }
}

extension Descriptor: Identifiable {
    public typealias ID = CBUUID
    
    public var id: CBUUID {
        self.cbDescriptor.uuid
    }
}
