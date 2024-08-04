//  Copyright (c) 2021 Manuel Fernandez-Peix Perez. All rights reserved.

import Foundation

/// Converts from and to Data?. This is useful for automatically returning data of the expected type, since
/// CoreBluetooth's API deals only with Data.
public protocol PeripheralDataConvertible {
    static func fromData(_ data: Data) -> Self?
    func toData() -> Data?
}

extension String: PeripheralDataConvertible {
    public static func fromData(_ data: Data) -> Self? {
        String(data: data, encoding: String.Encoding.utf8)
    }
    
    public func toData() -> Data? {
        self.data(using: String.Encoding.utf8)
    }
}

extension Bool: PeripheralDataConvertible {
    public static func fromData(_ data: Data) -> Self? {
        guard let numericValue = Int.fromData(data), (0...1).contains(numericValue) else { return nil }
        return numericValue == 1
    }
    
    public func toData() -> Data? {
        var value = self
        return Data(bytes: &value, count: MemoryLayout.size(ofValue: self))
    }
}

extension Data: PeripheralDataConvertible {
    public static func fromData(_ data: Data) -> Self? {
        return data
    }
    
    public func toData() -> Data? {
        return self
    }
}

extension PeripheralDataConvertible where Self: Numeric {
    public static func fromData(_ data: Data) -> Self? {
        guard data.count > 0 else { return nil }
        
        var value: Self = .zero
        _ = withUnsafeMutableBytes(of: &value) {
            data.copyBytes(to: $0.bindMemory(to: Self.self))
        }
        return value
    }
}

extension Int: PeripheralDataConvertible {
    public func toData() -> Data? {
        var value = self
        return .init(bytes: &value, count: MemoryLayout<Self>.size)
    }
}

extension Double: PeripheralDataConvertible {
    public func toData() -> Data? {
        var value = self
        return .init(bytes: &value, count: MemoryLayout<Self>.size)
    }
}

extension Float: PeripheralDataConvertible {
    public func toData() -> Data? {
        var value = self
        return .init(bytes: &value, count: MemoryLayout<Self>.size)
    }
}
