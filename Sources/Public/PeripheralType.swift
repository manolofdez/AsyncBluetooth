import Foundation

/// Protocol defining a remote peripheral device that supports Bluetooth low energy.
public protocol PeripheralType {
    var name: String? { get }
}
