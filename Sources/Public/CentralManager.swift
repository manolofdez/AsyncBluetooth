import Foundation
import CoreBluetooth
import os.log

/// An object that scans for, discovers, connects to, and manages peripherals using concurrency.
public class CentralManager {
    
    private typealias Utils = CentralManagerUtils
    
    fileprivate class DelegateWrapper: NSObject {
        private weak var centralManager: CentralManager?
        
        init(owner centralManager: CentralManager) {
            self.centralManager = centralManager
        }
    }
    
    private static let logger = Logger(
        subsystem: Bundle(for: CentralManager.self).bundleIdentifier ?? "",
        category: "centralManager"
    )
    
    public var bluetoothState: CBManagerState {
        self.cbCentralManager.state
    }
    
    public var isScanning: Bool {
        self.peripheralScanStreamContinuation != nil
    }
    
    private let cbCentralManager: CBCentralManager
    
    private let waitUntilReadyContinuations = CheckedContinuationListStorage<Void, Error>()
    private let connectToPeripheralContinuations = CheckedContinuationMapStorage<UUID, Void, Error>()
    private let cancelPeripheralConnectionContinuations = CheckedContinuationMapStorage<UUID, Void, Error>()
    private var peripheralScanStreamContinuation: AsyncStream<PeripheralScanData>.Continuation?
    
    private lazy var cbCentralManagerDelegate: CBCentralManagerDelegate = {
        DelegateWrapper(owner: self)
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
    
    // TODO: might need to be hidden behind an actor
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
                        continuation, forKey: peripheral.id
                    )
                } catch {
                    Self.logger.error("Unable to connect to \(peripheral.id) because a connection attempt is already in progress")
                    
                    continuation.resume(throwing: BluetoothError.connectingInProgress)
                    return
                }
                
                Self.logger.info("Connecting to \(peripheral.id)")
                
                self.cbCentralManager.connect(peripheral.cbPeripheral, options: options)
            }
        }
    }
    
    public func cancelPeripheralConnection(_ peripheral: Peripheral) async throws {
        let peripheralState = peripheral.cbPeripheral.state
        guard peripheralState == CBPeripheralState.connecting || peripheralState == CBPeripheralState.connected else {
            Self.logger.error("Unable to cancel connection: no connection to peripheral \(peripheral.id) exists nor being attempted")
            throw BluetoothError.noConnectionToPeripheralExists
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Task {
                do {
                    try await self.cancelPeripheralConnectionContinuations.addContinuation(
                        continuation, forKey: peripheral.id
                    )
                } catch {
                    Self.logger.error("Unable to disconnect from \(peripheral.id) because a disconnection attempt is already in progress")

                    continuation.resume(throwing: BluetoothError.disconnectingInProgress)
                    return
                }
                
                Self.logger.info("Disconnecting from \(peripheral.id)")
                
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
}

// MARK: CBCentralManagerDelegate

extension CentralManager.DelegateWrapper: CBCentralManagerDelegate {
    private typealias Utils = CentralManagerUtils
    
    private static var logger: Logger = {
        CentralManager.logger
    }()
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard let centralManager = self.centralManager else { return }
        
        if centralManager.bluetoothState != .poweredOn && centralManager.isScanning {
            centralManager.stopScan()
        }
        
        Task {
            guard let isBluetoothReadyResult = Utils.isBluetoothReady(centralManager.bluetoothState) else { return }

            await centralManager.waitUntilReadyContinuations.resumeAll(isBluetoothReadyResult)
        }
    }
    
    func centralManager(
        _ cbCentralManager: CBCentralManager,
        didDiscover cbPeripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber
    ) {
        let peripheralScanData = PeripheralScanData(
            peripheral: Peripheral(cbPeripheral),
            advertisementData: advertisementData,
            rssi: RSSI
        )

        guard let peripheralScanStreamContinuation = self.centralManager?.peripheralScanStreamContinuation else {
            Self.logger.info("Ignoring peripheral '\(peripheralScanData.peripheral.name ?? "unknown", privacy: .private)' because the central manager is not scanning")
            return
        }
        peripheralScanStreamContinuation.yield(peripheralScanData)
        
        Self.logger.info("Found peripheral \(peripheralScanData.peripheral.id)")
    }
    
    func centralManager(_ cbCentralManager: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task {
            Self.logger.info("Connected to peripheral \(peripheral.identifier)")
            
            do {
                try await self.centralManager?.connectToPeripheralContinuations.resumeContinuation(
                    .success(()), withKey: peripheral.identifier
                )
            } catch {
                Self.logger.error("Received onDidConnect without a continuation!")
            }
        }
    }
    
    func centralManager(
        _ cbCentralManager: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        Task {
            Self.logger.warning(
                "Failed to connect to peripheral \(peripheral.identifier) - error: \(error?.localizedDescription ?? "")"
            )
            
            do {
                try await self.centralManager?.connectToPeripheralContinuations.resumeContinuation(
                    .failure(BluetoothError.errorConnectingToPeripheral(error: error)), withKey: peripheral.identifier
                )
            } catch {
                Self.logger.error("Received onDidFailToConnect without a continuation!")
            }
        }
    }
    
    func centralManager(
        _ cbCentralManager: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.centralManager?.cancelPeripheralConnectionContinuations.resumeContinuation(
                    result, withKey: peripheral.identifier
                )
                Self.logger.info("Disconnected from \(peripheral.identifier)")
            } catch {
                Self.logger.info("Disconnected from \(peripheral.identifier) without a continuation")
            }
        }
    }
}
