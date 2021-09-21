import Foundation
import CoreBluetooth
import Combine

/// Contains the objects necessary to track a Central Manager's commands.
class CentralManagerContext {
    var scanState: ScanState = .notScanning

    private(set) lazy var waitUntilReadyExecutor = AsyncSerialExecutor<Void>()
    private(set) lazy var connectToPeripheralExecutor = AsyncExecutorMap<UUID, Void>()
    private(set) lazy var cancelPeripheralConnectionExecutor = AsyncExecutorMap<UUID, Void>()
}
