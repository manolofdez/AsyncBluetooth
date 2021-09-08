import Foundation
import XCTest
@testable import AsyncBluetooth

class PeripheralDataConversionTests: XCTestCase {

    // MARK: String
    
    func testRoundtripConvertionOfStringEmpty() {
        Self.assertRoundtripConvertion(of: "")
    }
    
    func testRoundtripConvertionOfString() {
        Self.assertRoundtripConvertion(of: "Lorem ipsum dolor sit amet")
    }
    
    // MARK: Booleans
    
    func testRoundtripConvertionOfBooleanTrue() {
        Self.assertRoundtripConvertion(of: true)
    }
    func testRoundtripConvertionOfBooleanFalse() {
        Self.assertRoundtripConvertion(of: false)
    }
    
    // MARK: Integer
    
    func testRoundtripConvertionOfInteger0() {
        Self.assertRoundtripConvertion(of: 0)
    }
    
    func testRoundtripConvertionOfIntegerWithPositiveValue() {
        Self.assertRoundtripConvertion(of: 1800)
    }
    
    func testRoundtripConvertionOfIntegerWithNegativeValue() {
        Self.assertRoundtripConvertion(of: -900)
    }

    // MARK: Float
    
    func testRoundtripConvertionOfFloat0() {
        Self.assertRoundtripConvertion(of: 0.0 as Float)
    }
    
    func testRoundtripConvertionOfFloatWithPositiveValue() {
        Self.assertRoundtripConvertion(of: 1800)
    }
    
    func testRoundtripConvertionOfFloatWithNegativeValue() {
        Self.assertRoundtripConvertion(of: -900)
    }

    func testRoundtripConvertionOfFloatWithDecimals() {
        Self.assertRoundtripConvertion(of: -3.14159265359 as Float)
    }

    // MARK: Utils
    
    /// Asserts that the given value can be converted to data and back to the original value.
    private static func assertRoundtripConvertion<T>(of value: T) where T: PeripheralDataConvertible & Equatable {
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
