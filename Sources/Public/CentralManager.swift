import Foundation
import CoreBluetooth
import os.log

public class CentralManager {
    
    private enum BluetoothError: Error {
        case bluetoothUnavailable
    }
    
    private static let logger = Logger(
        subsystem: Bundle(for: CentralManager.self).bundleIdentifier ?? "",
        category: "centralManager"
    )
    
    var state: CBManagerState {
        self.cbCentralManager.state
    }
    
    private let cbCentralManager: CBCentralManaging
    
    private var waitUntilReadyContinuation: CheckedContinuation<Void, Error>?
    private var scanState: ScanState = .idle
    
    private var isBluetoothReady: Bool? {
        switch self.state {
        case .poweredOn:
            return true
        case .unsupported, .unauthorized, .poweredOff:
            return false
        case .unknown, .resetting:
            return nil
        @unknown default:
            Self.logger.error("Unsupported CBManagerState received with raw value of \(self.state.rawValue)")
            return false
        }
    }
    
    private lazy var cbCentralManagerDelegate: CBCentralManagingDelegate = {
        CBCentralManagingDelegate(
            onDidUpdateState: { [weak self] in
                self?.onDidUpdateState()
            },
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
    
    // TODO: Handle multiple calls
    public func waitUntilReady() async throws {
        if let isBluetoothReady = self.isBluetoothReady {
            guard isBluetoothReady else {
                throw BluetoothError.bluetoothUnavailable
            }
            return
        }

        try await withCheckedThrowingContinuation { continuation in
            self.waitUntilReadyContinuation = continuation
        }
    }
    
    // TODO: Handle multiple calls
    public func scanForPeripherals(
        withServices serviceUUIDs: [CBUUID]?,
        options: [String : Any]? = nil
    ) -> AsyncStream<PeripheralScanData> {
        AsyncStream(PeripheralScanData.self) { continuation in
            continuation.onTermination = { @Sendable _ in
                self.cbCentralManager.stopScan()
                self.scanState = .idle
                
                Self.logger.info("Stopped scanning peripherals")
            }
            
            self.scanState = .scanning(continuation: continuation)
            
            self.cbCentralManager.scanForPeripherals(withServices: serviceUUIDs, options: options)
            
            Self.logger.info("Scanning for peripherals...")
        }
    }
    
    public func stopScan() {
        guard case ScanState.scanning(let continuation) = self.scanState else {
            Self.logger.warning("Unable to stop scanning because the central manager is not scanning!")
            return
        }
        continuation.finish()
    }
    
    // MARK: CBCentralManagingDelegate Callbacks
    
    private func onDidDiscoverPeripheral(_ peripheralScanData: PeripheralScanData) {
        guard case ScanState.scanning(let continuation) = self.scanState else {
            Self.logger.info("Ignoring peripheral '\(peripheralScanData.peripheral.name ?? "unknown", privacy: .private)' because the central manager is not scanning")
            return
        }
        continuation.yield(peripheralScanData)
    }
    
    private func onDidUpdateState() {
        if self.state != .poweredOn && self.scanState.isScanning {
            self.stopScan()
        }
        
        guard let waitUntilReadyContinuation = self.waitUntilReadyContinuation,
              let isBluetoothReady = self.isBluetoothReady else
        {
            return
        }
        
        if isBluetoothReady {
            waitUntilReadyContinuation.resume(throwing: BluetoothError.bluetoothUnavailable)
        } else {
            waitUntilReadyContinuation.resume()
        }
        
        self.waitUntilReadyContinuation = nil
    }
}

extension CentralManager {
    private enum ScanState {
        case idle
        case scanning(continuation: AsyncStream<PeripheralScanData>.Continuation)
        
        var isScanning: Bool {
            switch self {
            case .scanning:
                return true
            default:
                return false
            }
        }
    }
}
