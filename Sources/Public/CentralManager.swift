import Foundation
import CoreBluetooth
import os.log

/// An object that scans for, discovers, connects to, and manages peripherals using concurrency.
public class CentralManager {
    
    private typealias Utils = CentralManagerUtils
    
    private static let logger = Logger(
        subsystem: Bundle(for: CentralManager.self).bundleIdentifier ?? "",
        category: "centralManager"
    )
    
    var bluetoothState: CBManagerState {
        self.cbCentralManager.state
    }
    
    private let cbCentralManager: CBCentralManager
    
    private var waitUntilReadyContinuations = CheckedContinuationList<Void, Error>()
    private var peripheralScanStreamContinuation: AsyncStream<PeripheralScanData>.Continuation?
    private var connectToPeripheralContinuations = CheckedContinuationMap<UUID, Void, Error>()
    private var cancelPeripheralConnectionContinuations = CheckedContinuationMap<UUID, Void, Error>()
    
    private var isScanning: Bool {
        self.peripheralScanStreamContinuation != nil
    }
    
    private lazy var cbCentralManagerDelegate: CBCentralManagerDelegateWrapper = {
        CBCentralManagerDelegateWrapper(
            onDidUpdateState: { [weak self] in
                self?.onDidUpdateState()
            },
            onDidDiscoverPeripheral: { [weak self] peripheralScanData in
                self?.onDidDiscoverPeripheral(peripheralScanData)
            },
            onDidConnect: { [weak self] peripheral in
                self?.onDidConnect(peripheral)
            },
            onDidFailToConnect: { [weak self] peripheral, error in
                self?.onDidFailToConnect(peripheral, error: error)
            },
            onDidDisconnectPeripheral: { [weak self] peripheral, error in
                self?.onDidDisconnectPeripheral(peripheral, error: error)
            }
        )
    }()
    
    // MARK: Constructors

    public init(dispatchQueue: DispatchQueue? = nil, options: [String: Any]? = nil) {
        self.cbCentralManager = CBCentralManager(delegate: nil, queue: dispatchQueue, options: options)
        self.cbCentralManager.delegate = self.cbCentralManagerDelegate
    }
    
    // MARK: Public
    
    public func waitUntilReady() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Task {
                // Note since this happens asynchronously, we check whether we have a valid Bluetooth state or not.
                guard let isBluetoothReadyResult = Utils.isBluetoothReady(self.bluetoothState) else {
                    Self.logger.info("Waiting for bluetooth to be ready...")
                    
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
        guard !self.isScanning else {
            Self.logger.error("Scanning failed: already in progress")
            throw BluetoothError.scanningInProgress
        }
        return AsyncStream(PeripheralScanData.self) { continuation in
            continuation.onTermination = { @Sendable _ in
                self.cbCentralManager.stopScan()
                self.peripheralScanStreamContinuation = nil
                
                Self.logger.info("Stopped scanning peripherals")
            }
            
            self.peripheralScanStreamContinuation = continuation
            
            self.cbCentralManager.scanForPeripherals(withServices: serviceUUIDs, options: options)
            
            Self.logger.info("Scanning for peripherals...")
        }
    }
    
    public func stopScan() {
        guard let peripheralScanStreamContinuation = self.peripheralScanStreamContinuation else {
            Self.logger.warning("Unable to stop scanning because the central manager is not scanning!")
            return
        }
        
        peripheralScanStreamContinuation.finish()
        
        Self.logger.info("Stopping scan...")
    }
    
    public func connect(_ peripheral: Peripheral, options: [String : Any]? = nil) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Task {
                do {
                    try await self.connectToPeripheralContinuations.addContinuation(
                        continuation, forKey: peripheral.identifier
                    )
                } catch {
                    Self.logger.error("Unable to connect to \(peripheral.identifier) because a connection attempt is already in progress")
                    
                    continuation.resume(throwing: BluetoothError.connectingInProgress)
                    return
                }
                
                Self.logger.info("Connecting to \(peripheral.identifier)")
                
                self.cbCentralManager.connect(peripheral.cbPeripheral, options: options)
            }
        }
    }
    
    public func cancelPeripheralConnection(_ peripheral: Peripheral) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Task {
                do {
                    try await self.cancelPeripheralConnectionContinuations.addContinuation(
                        continuation, forKey: peripheral.identifier
                    )
                } catch {
                    Self.logger.error("Unable to disconnect from \(peripheral.identifier) because a disconnection attempt is already in progress")

                    continuation.resume(throwing: BluetoothError.disconnectingInProgress)
                    return
                }
                
                Self.logger.info("Disconnecting from \(peripheral.identifier)")
                
                self.cbCentralManager.cancelPeripheralConnection(peripheral.cbPeripheral)
            }
        }
    }
    
    public func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [Peripheral] {
        self.cbCentralManager.retrievePeripherals(withIdentifiers: identifiers).map { Peripheral($0) }
    }
    
    public func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [Peripheral] {
        self.cbCentralManager.retrieveConnectedPeripherals(withServices: serviceUUIDs).map { Peripheral($0) }
    }

    @available(macOS, unavailable)
    public static func supports(_ features: CBCentralManager.Feature) -> Bool {
        CBCentralManager.supports(features)
    }
    
    // MARK: CBCentralManagingDelegate Callbacks
    
    private func onDidUpdateState() {
        if self.bluetoothState != .poweredOn && self.isScanning {
            self.stopScan()
        }
        
        Task {
            guard let isBluetoothReadyResult = Utils.isBluetoothReady(self.bluetoothState) else { return }

            await self.waitUntilReadyContinuations.resumeAll(isBluetoothReadyResult)
        }
    }
    
    private func onDidDiscoverPeripheral(_ peripheralScanData: PeripheralScanData) {
        guard let peripheralScanStreamContinuation = peripheralScanStreamContinuation else {
            Self.logger.info("Ignoring peripheral '\(peripheralScanData.peripheral.name ?? "unknown", privacy: .private)' because the central manager is not scanning")
            return
        }
        peripheralScanStreamContinuation.yield(peripheralScanData)
        
        Self.logger.info("Found peripheral \(peripheralScanData.peripheral.identifier)")
    }
    
    private func onDidConnect(_ peripheral: CBPeripheral) {
        Task {
            Self.logger.info("Connected to peripheral \(peripheral.identifier)")
            
            do {
                try await self.connectToPeripheralContinuations.resumeContinuation(
                    .success(()), withKey: peripheral.identifier
                )
            } catch {
                Self.logger.error("Received onDidConnect without a continuation!")
            }
        }
    }
    
    private func onDidFailToConnect(_ peripheral: CBPeripheral, error: Error?) {
        Task {
            Self.logger.warning("Failed to connect to peripheral \(peripheral.identifier) - error: \(error?.localizedDescription ?? "")")
            
            do {
                try await self.connectToPeripheralContinuations.resumeContinuation(
                    .failure(BluetoothError.errorConnectingToPeripheral(error: error)), withKey: peripheral.identifier
                )
            } catch {
                Self.logger.error("Received onDidFailToConnect without a continuation!")
            }
        }
    }
    
    private func onDidDisconnectPeripheral(_ peripheral: CBPeripheral, error: Error?) {
        let result: Result<Void, Error>
        if let error = error {
            result = .failure(error)
        } else {
            result = .success(())
        }
        
        Task {
            do {
                try await self.cancelPeripheralConnectionContinuations.resumeContinuation(
                    result, withKey: peripheral.identifier
                )
                Self.logger.info("Disconnected from \(peripheral.identifier)")
            } catch {
                Self.logger.info("Disconnected from \(peripheral.identifier) without a continuation")
            }
        }
    }
}
