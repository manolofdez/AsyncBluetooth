//  Copyright (c) 2021 Manuel Fernandez-Peix Perez. All rights reserved.

import Foundation
import CoreBluetooth
import Combine
import os.log

/// An object that scans for, discovers, connects to, and manages peripherals using concurrency.
public class CentralManager {

    private typealias Utils = CentralManagerUtils
    
    fileprivate class DelegateWrapper: NSObject {
        private let context: CentralManagerContext
        private let logger: AsyncBluetoothLogging

        init(context: CentralManagerContext, logger: AsyncBluetoothLogging) {
            self.context = context
            self.logger = logger
        }
    }
    
    public var bluetoothState: CBManagerState {
        self.cbCentralManager.state
    }
    
    public var isScanning: Bool {
        self.context.isScanning
    }
    
    public lazy var eventPublisher: AnyPublisher<CentralManagerEvent, Never> = {
        self.context.eventSubject.eraseToAnyPublisher()
    }()
    
    private let cbCentralManager: CBCentralManager
    private let context: CentralManagerContext
    private let cbCentralManagerDelegate: CBCentralManagerDelegate
    private let logger: AsyncBluetoothLogging

    // MARK: Constructors

    public init(dispatchQueue: DispatchQueue? = nil,
                logger: AsyncBluetoothLogging,
                options: [String: Any]? = nil) {
        self.context = CentralManagerContext()
        self.cbCentralManagerDelegate = DelegateWrapper(context: self.context, logger: logger)
        self.cbCentralManager = CBCentralManager(delegate: cbCentralManagerDelegate, queue: dispatchQueue, options: options)
        self.logger = logger
    }
    
    // MARK: Public
    
    /// Waits until Bluetooth is ready. If the Bluetooth state is unknown or resetting, it
    /// will wait until a `centralManagerDidUpdateState` message is received. If Bluetooth is powered off,
    /// unsupported or unauthorized, an error will be thrown. Otherwise we'll continue.
    public func waitUntilReady() async throws {
        guard let isBluetoothReadyResult = Utils.isBluetoothReady(self.bluetoothState) else {
            logger.info("Waiting for bluetooth to be ready...")
            
            try await self.context.waitUntilReadyExecutor.enqueue { [weak self] in
                // Note we need to check again here in case the Bluetooth state was updated after we last
                // checked but before the work was enqueued. Otherwise we could wait indefinitely.
                guard let self = self, let isBluetoothReadyResult = Utils.isBluetoothReady(self.bluetoothState) else {
                    return
                }
                Task {
                    await self.context.waitUntilReadyExecutor.flush(isBluetoothReadyResult)
                }
            }
            return
        }

        switch isBluetoothReadyResult {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }
    
    /// Scans for peripherals that are advertising services.
    public func scanForPeripherals(
        withServices serviceUUIDs: [CBUUID]?,
        options: [String : Any]? = nil
    ) async throws -> AsyncStream<ScanData> {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                // Note that the enqueue call will remain awaiting until the stream is terminated. This
                // means that we can end up in a state were the continuation is used to send the stream,
                // and yet we want to throw an error (e.g. calling `cancellAllOperations` while scanning).
                // To avoid crashing, we check whether the continuation has been used before.
                var isContinuationUsed = false
                
                do {
                    try await self.context.scanForPeripheralsExecutor.enqueue {
                        guard !isContinuationUsed else { return }
                        isContinuationUsed = true
                        
                        let scanDataStream = self.createScanDataStream(
                            withServices: serviceUUIDs,
                            options: options
                        )
                        continuation.resume(returning: scanDataStream)
                    }
                } catch {
                    guard !isContinuationUsed else { return }
                    isContinuationUsed = true
                    
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Asks the central manager to stop scanning for peripherals.
    public func stopScan() async {
        guard let continuation = await self.context.scanForPeripheralsContext.continuation else {
            logger.warning("Unable to stop scanning because the central manager is not scanning!")
            return
        }
        
        logger.info("Stopping scan...")
        
        continuation.finish()
    }
    
    /// Establishes a local connection to a peripheral.
    public func connect(_ peripheral: Peripheral, options: [String : Any]? = nil) async throws {
        guard await !self.context.connectToPeripheralExecutor.hasWorkForKey(peripheral.identifier) else {
            logger.error("Unable to connect to \(peripheral.identifier) because a connection attempt is already in progress")

            throw BluetoothError.connectingInProgress
        }
        
        try await self.context.connectToPeripheralExecutor.enqueue(withKey: peripheral.identifier) {
            self.logger.info("Connecting to \(peripheral.identifier)")
            
            self.cbCentralManager.connect(peripheral.cbPeripheral, options: options)
        }
    }
    
    /// Cancels an active or pending local connection to a peripheral.
    public func cancelPeripheralConnection(_ peripheral: Peripheral) async throws {
        let peripheralState = peripheral.cbPeripheral.state
        guard peripheralState == CBPeripheralState.connecting || peripheralState == CBPeripheralState.connected else {
            logger.error("Unable to cancel connection: no connection to peripheral \(peripheral.identifier) exists nor being attempted")
            throw BluetoothError.noConnectionToPeripheralExists
        }
        
        guard await !self.context.cancelPeripheralConnectionExecutor.hasWorkForKey(peripheral.identifier) else {
            logger.error("Unable to disconnect from \(peripheral.identifier) because a disconnection attempt is already in progress")

            throw BluetoothError.disconnectingInProgress
        }

        // cancel ongoing connection
        if await self.context.connectToPeripheralExecutor.hasWorkForKey(peripheral.identifier) {
            try await self.context.connectToPeripheralExecutor.setWorkCompletedForKey(peripheral.identifier, result: .failure(BluetoothError.cancelledConnectionToPeripheral))
        }
        
        try await self.context.cancelPeripheralConnectionExecutor.enqueue(withKey: peripheral.identifier) {
            self.logger.info("Disconnecting from \(peripheral.identifier)")
            
            self.cbCentralManager.cancelPeripheralConnection(peripheral.cbPeripheral)
        }
    }
    
    /// Returns a list of known peripherals by their identifiers.
    public func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [Peripheral] {
        self.cbCentralManager.retrievePeripherals(withIdentifiers: identifiers).map { Peripheral($0, logger: logger) }
    }
    
    /// Returns a list of the peripherals connected to the system whose services match a given set of criteria.
    public func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [Peripheral] {
        self.cbCentralManager.retrieveConnectedPeripherals(withServices: serviceUUIDs).map { Peripheral($0, logger: logger) }
    }
    
    /// Cancels all pending operations, stops scanning and awaiting for any responses.
    /// - Note: Operation for Peripherals will not be cancelled. To do that, call `cancelAllOperations()` on the `Peripheral`.
    public func cancelAllOperations() async throws {
        if isScanning {
            await self.stopScan()
        }
        try await self.context.flush(error: BluetoothError.operationCancelled)
    }

    /// Returns a Boolean that indicates whether the device supports a specific set of features.
    @available(macOS, unavailable)
    public static func supports(_ features: CBCentralManager.Feature) -> Bool {
        CBCentralManager.supports(features)
    }
    
    /// Creates the async stream where scan data will get added as part of scanning for peripherals.
    /// - Note: The stream is responsable for starting scan.
    private func createScanDataStream(
        withServices serviceUUIDs: [CBUUID]?,
        options: [String : Any]? = nil
    ) -> AsyncStream<ScanData> {
        AsyncStream(ScanData.self) { continuation in
            continuation.onTermination = { @Sendable _ in
                self.cbCentralManager.stopScan()
                self.logger.info("Stopped scanning peripherals")
                
                Task {
                    await self.context.scanForPeripheralsContext.setContinuation(nil)

                    do {
                        try await self.context.scanForPeripheralsExecutor.setWorkCompletedWithResult(.success(()))
                    } catch {
                        self.logger.warning("Scanning stopped without a continuation!")
                    }
                }
            }

            Task {
                await self.context.scanForPeripheralsContext.setContinuation(continuation)

                self.cbCentralManager.scanForPeripherals(withServices: serviceUUIDs, options: options)

                logger.info("Scanning for peripherals...")
            }
        }
    }
}

// MARK: CBCentralManagerDelegate

extension CentralManager.DelegateWrapper: CBCentralManagerDelegate {
    private typealias Utils = CentralManagerUtils

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task {
            defer {
                self.context.eventSubject.send(.didUpdateState(state: central.state))
            }
            
            guard let isBluetoothReadyResult = Utils.isBluetoothReady(central.state) else { return }

            await self.context.waitUntilReadyExecutor.flush(isBluetoothReadyResult)
        }
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        self.context.eventSubject.send(.willRestoreState(state: dict))
    }
    
    func centralManager(
        _ cbCentralManager: CBCentralManager,
        didDiscover cbPeripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber
    ) {
        let scanData = ScanData(
            peripheral: Peripheral(cbPeripheral, logger: logger),
            advertisementData: advertisementData,
            rssi: RSSI
        )

        Task {
            guard let continuation = await self.context.scanForPeripheralsContext.continuation else {
                logger.info("Ignoring peripheral '\(scanData.peripheral.name ?? "unknown")' because the central manager is not scanning")
                return
            }
            continuation.yield(scanData)
            
            logger.info("Found peripheral '\(scanData.peripheral.name ?? "(unknown)")'" +
                        " with ID: \(scanData.peripheral.identifier)")
        }
    }
    
    func centralManager(_ cbCentralManager: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task {
            logger.info("Connected to peripheral \(peripheral.identifier)")
            
            do {
                try await self.context.connectToPeripheralExecutor.setWorkCompletedForKey(
                    peripheral.identifier, result:.success(())
                )
            } catch {
                logger.info("Received onDidConnect without a continuation")
            }
            
            self.context.eventSubject.send(
                .didConnectPeripheral(peripheral: Peripheral(peripheral, logger: logger))
            )
        }
    }
    
    func centralManager(
        _ cbCentralManager: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        Task {
            logger.warning(
                "Failed to connect to peripheral \(peripheral.identifier) - error: \(error?.localizedDescription ?? "")"
            )
            
            do {
                try await self.context.connectToPeripheralExecutor.setWorkCompletedForKey(
                    peripheral.identifier, result: .failure(BluetoothError.errorConnectingToPeripheral(error: error))
                )
            } catch {
                logger.error("Received onDidFailToConnect without a continuation!")
            }
        }
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        timestamp: CFAbsoluteTime,
        isReconnecting: Bool,
        error: Error?
    ) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.context.cancelPeripheralConnectionExecutor.setWorkCompletedForKey(
                    peripheral.identifier, result: result
                )
                logger.info("Disconnected from \(peripheral.identifier)")
            } catch {
                logger.info("Disconnected from \(peripheral.identifier) without a continuation")
            }
            
            self.context.eventSubject.send(
                .didDisconnectPeripheral(peripheral: Peripheral(peripheral, logger: logger), isReconnecting: isReconnecting, error: error)
            )
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
                try await self.context.cancelPeripheralConnectionExecutor.setWorkCompletedForKey(
                    peripheral.identifier, result: result
                )
                logger.info("Disconnected from \(peripheral.identifier)")
            } catch {
                logger.info("Disconnected from \(peripheral.identifier) without a continuation")
            }
            
            self.context.eventSubject.send(
                .didDisconnectPeripheral(peripheral: Peripheral(peripheral, logger: logger), isReconnecting: false, error: error)
            )
        }
    }
}
