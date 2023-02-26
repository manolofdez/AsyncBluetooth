//  Copyright (c) 2021 Manuel Fernandez-Peix Perez. All rights reserved.

import Foundation
import CoreBluetooth
import Combine

/// Contains the objects necessary to track a Peripheral's commands.
class AsyncPeripheralContext {
    private(set) lazy var characteristicValueUpdatedSubject = PassthroughSubject<AsyncCharacteristic, Never>()
    
    private(set) lazy var readRSSIExecutor = AsyncSerialExecutor<NSNumber>()
    private(set) lazy var discoverServiceExecutor = AsyncSerialExecutor<Void>()
    private(set) lazy var discoverIncludedServicesExecutor = AsyncExecutorMap<CBUUID, Void>()
    private(set) lazy var discoverCharacteristicsExecutor = AsyncExecutorMap<CBUUID, Void>()
    private(set) lazy var readCharacteristicValueExecutor = AsyncExecutorMap<CBUUID, Void>()
    private(set) lazy var writeCharacteristicValueExecutor = AsyncExecutorMap<CBUUID, Void>()
    private(set) lazy var setNotifyValueExecutor = AsyncExecutorMap<CBUUID, Void>()
    private(set) lazy var discoverDescriptorsExecutor = AsyncExecutorMap<CBUUID, Void>()
    private(set) lazy var readDescriptorValueExecutor = AsyncExecutorMap<CBUUID, Void>()
    private(set) lazy var writeDescriptorValueExecutor = AsyncExecutorMap<CBUUID, Void>()
    private(set) lazy var openL2CAPChannelExecutor = AsyncSerialExecutor<CBL2CAPChannel?>()
}
