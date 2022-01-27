//  Copyright (c) 2021 Manuel Fernandez-Peix Perez. All rights reserved.

import Foundation
import CoreBluetooth
import Combine

/// Contains the objects necessary to track a Central Manager's commands.
class CentralManagerContext {
    actor ScanForPeripheralsContext {
        let onContinuationChanged: (_ isScanning: Bool) -> Void
        
        init(onContinuationChanged: @escaping (_ isScanning: Bool) -> Void) {
            self.onContinuationChanged = onContinuationChanged
        }
        
        /// Continuation used for yielding scan results, and finishing scans.
        private(set) var continuation: AsyncStream<ScanData>.Continuation?
        
        func setContinuation(_ continuation: AsyncStream<ScanData>.Continuation?) -> Void {
            self.continuation = continuation
            self.onContinuationChanged(continuation != nil)
        }
    }
    
    private(set) var isScanning = false
    
    private(set) lazy var waitUntilReadyExecutor = AsyncSerialExecutor<Void>()
    private(set) lazy var scanForPeripheralsExecutor = AsyncSerialExecutor<Void>()
    private(set) lazy var scanForPeripheralsContext = ScanForPeripheralsContext { [weak self] isScanning in
        self?.isScanning = isScanning
    }
    private(set) lazy var connectToPeripheralExecutor = AsyncExecutorMap<UUID, Void>()
    private(set) lazy var cancelPeripheralConnectionExecutor = AsyncExecutorMap<UUID, Void>()
    private(set) lazy var eventSubject = PassthroughSubject<CentralManagerEvent, Never>()
}
