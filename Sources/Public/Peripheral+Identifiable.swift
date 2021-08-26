import Foundation

extension Peripheral: Identifiable {
    public typealias ID = UUID
    
    public var id: UUID {
        self.identifier
    }
}
