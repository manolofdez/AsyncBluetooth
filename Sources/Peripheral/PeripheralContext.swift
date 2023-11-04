//  Copyright (c) 2021 Manuel Fernandez-Peix Perez. All rights reserved.

import Foundation
import CoreBluetooth
import Combine

/// Contains the objects necessary to track a Peripheral's commands.
class PeripheralContext {
    private(set) lazy var characteristicValueUpdatedSubject = PassthroughSubject<Characteristic, Never>()
    private(set) lazy var invalidatedServicesSubject = PassthroughSubject<[Service], Never>()
    
    private(set) lazy var readRSSIExecutor = {
        let executor = AsyncSerialExecutor<NSNumber>()
        flushableExecutors.append(executor)
        return executor
    }()
    
    private(set) lazy var discoverServiceExecutor = {
        let executor = AsyncSerialExecutor<Void>()
        flushableExecutors.append(executor)
        return executor
    }()
    
    private(set) lazy var discoverIncludedServicesExecutor = {
        let executor = AsyncExecutorMap<CBUUID, Void>()
        flushableExecutors.append(executor)
        return executor
    }()
    
    private(set) lazy var discoverCharacteristicsExecutor = {
        let executor = AsyncExecutorMap<CBUUID, Void>()
        flushableExecutors.append(executor)
        return executor
    }()
    
    private(set) lazy var readCharacteristicValueExecutor = {
        let executor = AsyncExecutorMap<CBUUID, Void>()
        flushableExecutors.append(executor)
        return executor
    }()
    
    private(set) lazy var writeCharacteristicValueExecutor = {
        let executor = AsyncExecutorMap<CBUUID, Void>()
        flushableExecutors.append(executor)
        return executor
    }()
    
    private(set) lazy var setNotifyValueExecutor = {
        let executor = AsyncExecutorMap<CBUUID, Void>()
        flushableExecutors.append(executor)
        return executor
    }()
    
    private(set) lazy var discoverDescriptorsExecutor = {
        let executor = AsyncExecutorMap<CBUUID, Void>()
        flushableExecutors.append(executor)
        return executor
    }()
    
    private(set) lazy var readDescriptorValueExecutor = {
        let executor = AsyncExecutorMap<CBUUID, Void>()
        flushableExecutors.append(executor)
        return executor
    }()
    
    private(set) lazy var writeDescriptorValueExecutor = {
        let executor = AsyncExecutorMap<CBUUID, Void>()
        flushableExecutors.append(executor)
        return executor
    }()
    
    private(set) lazy var openL2CAPChannelExecutor = {
        let executor = AsyncSerialExecutor<CBL2CAPChannel?>()
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
