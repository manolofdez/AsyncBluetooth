import Foundation
import XCTest
@testable import AsyncBluetooth

class CentralManagerUtilsTests: XCTestCase {
    func testIsBluetoothReady() throws {
        XCTAssertNotNil(
            try CentralManagerUtils.isBluetoothReady(.poweredOn)?.get()
        )

        XCTAssertNil(CentralManagerUtils.isBluetoothReady(.resetting))

        XCTAssertEqual(
            CentralManagerUtils.isBluetoothReady(.poweredOff)?.error?.extractReason,
            .poweredOff
        )

        XCTAssertEqual(
            CentralManagerUtils.isBluetoothReady(.unauthorized)?.error?.extractReason,
            .unauthorized
        )
    }
}

private extension Result<(), Error> {
    var error: Error? {
        switch self {
        case .success: return nil
        case .failure(let error): return error
        }
    }
}

private extension Error {
    var extractReason: BluetoothUnavailableReason? {
        guard let error = self as? BluetoothError else {
            return nil
        }

        switch error {
        case .bluetoothUnavailable(let reason): return reason
        default: return nil
        }
    }
}
