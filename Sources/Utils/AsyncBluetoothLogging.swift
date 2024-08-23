// Copyright (c) 2024 Manuel Fernandez. All rights reserved.

import Foundation
import os.log

public final class AsyncBluetoothLogging: Sendable {
    
    private(set) static var isEnabled = true
    
    private static var loggers: [String: Logger] = [:]
    private static let disabledLogger = Logger(OSLog.disabled)
    
    public static func setEnabled(_ isEnabled: Bool) {
        Self.isEnabled = isEnabled
    }
    
    static func logger(for category: String) -> Logger {
        guard Self.isEnabled else { return Self.disabledLogger }
        
        if let logger = Self.loggers[category] {
            return logger
        }
        
        let logger = Logger(
            subsystem: Bundle(for: CentralManager.self).bundleIdentifier ?? "",
            category: category
        )
        
        Self.loggers[category] = logger
        
        return logger
    }
}

typealias Logging = AsyncBluetoothLogging
