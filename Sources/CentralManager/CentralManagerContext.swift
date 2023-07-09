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
    
    private(set) lazy var scanForPeripheralsContext = ScanForPeripheralsContext { [weak self] isScanning in
        self?.isScanning = isScanning
    }
    
    private(set) lazy var eventSubject = PassthroughSubject<CentralManagerEvent, Never>()
    
    private(set) lazy var waitUntilReadyExecutor = {
        let executor = AsyncSerialExecutor<Void>()
        flushableExecutors.append(executor)
        return executor
    }()
    
    private(set) lazy var scanForPeripheralsExecutor = {
        let executor = AsyncSerialExecutor<Void>()
        flushableExecutors.append(executor)
        return executor
    }()
    
    private(set) lazy var connectToPeripheralExecutor = {
        let executor = AsyncExecutorMap<UUID, Void>()
        flushableExecutors.append(executor)
        return executor
    }()
    
    private(set) lazy var cancelPeripheralConnectionExecutor = {
        let executor = AsyncExecutorMap<UUID, Void>()
        flushableExecutors.append(executor)
        return executor
    }()
    
    private var flushableExecutors: [FlushableExecutor] = []
    
    func flush(error: Error) async throws {
        for flushableExecutor in flushableExecutors {
            try await flushableExecutor.flush(error: error)
        }
    }
}
