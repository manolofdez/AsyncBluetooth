import Foundation
import XCTest
@testable import AsyncBluetooth

class CentralManagerTests: XCTestCase {
    
    // MARK: Scanning
    
//    func testScanForPeripheralsStopsIteratingAfterStoppingScan() async {
//        let cbCentralManagerMock = CBCentralManagerMock()
//        let centralManager = CentralManager(cbCentralManager: cbCentralManagerMock)
//
//        
//        guard let peripheralScanStream = try? centralManager.scanForPeripherals(withServices: nil, options: nil) else {
//            XCTFail("Scanning in progress")
//            return
//        }
//        for await _ in peripheralScanStream {
//            centralManager.stopScan()
//        }
//
//        XCTAssert(!cbCentralManagerMock.isScanning)
//    }
//    
//    // MARK: Waiting for readiness
//    
//    func testWaitingForReadinessRespondsToAllRequests() async {
//        let cbCentralManagerMock = CBCentralManagerMock()
//        let centralManager = CentralManager(cbCentralManager: cbCentralManagerMock)
//
//        cbCentralManagerMock.state = .unknown
//        
//        let waitTask1 = Task {
//            try await centralManager.waitUntilReady()
//        }
//        let waitTask2 = Task {
//            try await centralManager.waitUntilReady()
//        }
//        
//        Self.performDelayed {
//            cbCentralManagerMock.state = .poweredOn
//        }
//        
//        do {
//            try await waitTask1.value
//            try await waitTask2.value
//        } catch {
//            XCTFail("Failed waiting: \(error)")
//        }
//    }
//    
//    @discardableResult
//    private static func performDelayed(
//        timeInterval: TimeInterval = 0,
//        block: @escaping () -> Void
//    ) -> Task<Void, Error> {
//        Task {
//            Thread.sleep(forTimeInterval: timeInterval)
//            block()
//        }
//    }
}
