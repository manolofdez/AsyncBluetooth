import Foundation
import CoreBluetooth
import os.log

public class CentralManager {
    
    private static let logger = Logger(
        subsystem: Bundle(for: CentralManager.self).bundleIdentifier!,
        category: "centralManager"
    )
    
    private let cbCentralManager: CBCentralManaging
    private var state: State = .idle
    
    private lazy var cbCentralManagerDelegate: CBCentralManagingDelegate = {
        CBCentralManagingDelegate(
            onDidDiscoverPeripheral: { [weak self] peripheralScanData in
                self?.onDidDiscoverPeripheral(peripheralScanData)
            }
        )
    }()

    public convenience init(dispatchQueue: DispatchQueue? = nil, options: [String: Any]? = nil) {
        let cbCentralManager = CBCentralManager(delegate: nil, queue: dispatchQueue, options: options)
        self.init(cbCentralManager: cbCentralManager)
    }
    
    init(cbCentralManager: CBCentralManaging) {
        self.cbCentralManager = cbCentralManager
        self.cbCentralManager.delegate = self.cbCentralManagerDelegate
    }
    
    public func scanForPeripherals(
        withServices serviceUUIDs: [CBUUID]?,
        options: [String : Any]? = nil
    ) -> AsyncStream<PeripheralScanData> {
        AsyncStream(PeripheralScanData.self) { continuation in
            continuation.onTermination = { @Sendable _ in
                self.cbCentralManager.stopScan()
                self.state = .idle
                
                Self.logger.info("Stopped scanning peripherals")
            }
            
            self.state = .scanning(continuation: continuation)
            
            self.cbCentralManager.scanForPeripherals(withServices: serviceUUIDs, options: options)
            
            Self.logger.info("Scanning for peripherals...")
        }
    }
    
    public func stopScan() {
        guard case State.scanning(let continuation) = self.state else {
            Self.logger.warning("Unable to stop scanning because the central manager is not scanning!")
            return
        }
        continuation.finish()
    }
    
    private func onDidDiscoverPeripheral(_ peripheralScanData: PeripheralScanData) {
        guard case State.scanning(let continuation) = self.state else {
            Self.logger.info("Ignoring peripheral '\(peripheralScanData.peripheral.name ?? "unknown", privacy: .private)' because the central manager is not scanning")
            return
        }
        continuation.yield(peripheralScanData)
    }
}

extension CentralManager {
    private enum State {
        case idle
        case scanning(continuation: AsyncStream<PeripheralScanData>.Continuation)
    }
}
