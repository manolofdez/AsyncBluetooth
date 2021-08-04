import Foundation
import XCTest
@testable import AsyncBluetooth

class CentralManagerTests: XCTestCase {
    func testScanForPeripheralsStopsIteratingAfterStoppingScan() async {
        let cbCentralManagerMock = CBCentralManagerMock()
        let centralManager = CentralManager(cbCentralManager: cbCentralManagerMock)
        
        let peripheralScanStream = centralManager.scanForPeripherals(withServices: nil, options: nil)
        for await _ in peripheralScanStream {
            centralManager.stopScan()
        }
    
        XCTAssert(!cbCentralManagerMock.isScanning)
    }
}
