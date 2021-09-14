import Foundation
import CoreBluetooth

public struct Service {
    let cbService: CBService
    
    public var isPrimary: Bool {
        self.cbService.isPrimary
    }
    
    public var includedServices: [Service]? {
        self.cbService.includedServices?.map { Service($0) }
    }
    
    public var discoveredCharacteristics: [Characteristic]? {
        self.cbService.characteristics?.map { Characteristic($0) }
    }
    
    init(_ cbService: CBService) {
        self.cbService = cbService
    }
}
