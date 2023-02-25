//  Copyright (c) 2021 Manuel Fernandez-Peix Perez. All rights reserved.

import Foundation
import os.log

struct AsyncSerialExecutorConstants {
    static let logger = Logger(
        subsystem: Bundle(for: AsyncPeripheral.self).bundleIdentifier ?? "",
        category: "asyncSerialExecutor"
    )
    
    private init() {}
}
