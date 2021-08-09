import Foundation
import CoreBluetooth
import os.log

public class CentralManager {
    
    private typealias Utils = CentralManagerUtils
    
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
    
    private static let logger = Logger(
        subsystem: Bundle(for: CentralManager.self).bundleIdentifier ?? "",
        category: "centralManager"
    )
    
    var bluetoothState: CBManagerState {
        self.cbCentralManager.state
    }
    
    private let cbCentralManager: CBCentralManaging
    
    private var waitUntilReadyContinuations = CheckedContinuationList<Void, Error>()
    private var scanState: ScanState = .idle
    
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
    
    // MARK: Constructors

    public convenience init(dispatchQueue: DispatchQueue? = nil, options: [String: Any]? = nil) {
        let cbCentralManager = CBCentralManager(delegate: nil, queue: dispatchQueue, options: options)
        self.init(cbCentralManager: cbCentralManager)
    }
    
    init(cbCentralManager: CBCentralManaging) {
        self.cbCentralManager = cbCentralManager
        self.cbCentralManager.delegate = self.cbCentralManagerDelegate
    }
    
    // MARK: Public
    
    public func waitUntilReady() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Task {
                // Note since this happens asynchronously, we check whether we have a valid Bluetooth state or not.
                guard let isBluetoothReadyResult = Utils.isBluetoothReady(self.bluetoothState) else {
                    await self.waitUntilReadyContinuations.append(continuation)
                    return
                }
                continuation.resume(with: isBluetoothReadyResult)
            }
        }
    }
    
    public func scanForPeripherals(
        withServices serviceUUIDs: [CBUUID]?,
        options: [String : Any]? = nil
    ) throws -> AsyncStream<PeripheralScanData> {
        guard case ScanState.idle = self.scanState else {
            Self.logger.error("Scanning failed: already in progress")
            throw BluetoothError.scanningInProgress
        }
        return AsyncStream(PeripheralScanData.self) { continuation in
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
    
    private func onDidUpdateState() {
        if self.bluetoothState != .poweredOn && self.scanState.isScanning {
            self.stopScan()
        }
        
        Task {
            guard let isBluetoothReadyResult = Utils.isBluetoothReady(self.bluetoothState) else { return }

            await self.waitUntilReadyContinuations.resumeAll(isBluetoothReadyResult)
        }
    }
    
    private func onDidDiscoverPeripheral(_ peripheralScanData: PeripheralScanData) {
        guard case ScanState.scanning(let continuation) = self.scanState else {
            Self.logger.info("Ignoring peripheral '\(peripheralScanData.peripheral.name ?? "unknown", privacy: .private)' because the central manager is not scanning")
            return
        }
        continuation.yield(peripheralScanData)
    }
}
