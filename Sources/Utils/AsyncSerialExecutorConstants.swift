import Foundation
import os.log

struct AsyncSerialExecutorConstants {
    static let logger = Logger(
        subsystem: Bundle(for: Peripheral.self).bundleIdentifier ?? "",
        category: "asyncSerialExecutor"
    )
    
    private init() {}
}
