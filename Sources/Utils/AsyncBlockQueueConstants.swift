import Foundation
import os.log

struct AsyncBlockQueueConstants {
    static let logger = Logger(
        subsystem: Bundle(for: Peripheral.self).bundleIdentifier ?? "",
        category: "asyncBlockQueue"
    )
    
    private init() {}
}
