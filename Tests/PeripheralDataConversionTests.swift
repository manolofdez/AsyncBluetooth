import Foundation
import XCTest
@testable import AsyncBluetooth

class PeripheralDataConversionTests: XCTestCase {

    // MARK: String
    
    func testRoundtripConversionOfStringEmpty() {
        Self.assertRoundtripConversion(of: "")
    }
    
    func testRoundtripConversionOfString() {
        Self.assertRoundtripConversion(of: "Lorem ipsum dolor sit amet")
    }
    
    // MARK: Booleans
    
    func testRoundtripConversionOfBooleanTrue() {
        Self.assertRoundtripConversion(of: true)
    }
    func testRoundtripConversionOfBooleanFalse() {
        Self.assertRoundtripConversion(of: false)
    }
    
    // MARK: Integer
    
    func testRoundtripConversionOfInteger0() {
        Self.assertRoundtripConversion(of: 0)
    }
    
    func testRoundtripConversionOfIntegerWithPositiveValue() {
        Self.assertRoundtripConversion(of: 1800)
    }
    
    func testRoundtripConversionOfIntegerWithNegativeValue() {
        Self.assertRoundtripConversion(of: -900)
    }

    // MARK: Float
    
    func testRoundtripConversionOfFloat0() {
        Self.assertRoundtripConversion(of: 0.0 as Float)
    }
    
    func testRoundtripConversionOfFloatWithPositiveValue() {
        Self.assertRoundtripConversion(of: 1800)
    }
    
    func testRoundtripConversionOfFloatWithNegativeValue() {
        Self.assertRoundtripConversion(of: -900)
    }

    func testRoundtripConversionOfFloatWithDecimals() {
        Self.assertRoundtripConversion(of: -3.14159265359 as Float)
    }

    // MARK: Utils
    
    /// Asserts that the given value can be converted to data and back to the original value.
    private static func assertRoundtripConversion<T>(of value: T) where T: PeripheralDataConvertible & Equatable {
        guard let data = value.toData() else {
            XCTFail("Failed to convert value \(value) of type \(T.self) to Data")
            return
        }
        guard let parsedData = T.fromData(data) else {
            XCTFail("Failed to converted data back to \(T.self)")
            return
        }
        XCTAssert(value == parsedData)
    }
}
