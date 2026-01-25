// Copyright (c) 2024 Manuel Fernandez. All rights reserved.

import Foundation
import os.log

public final class AsyncBluetoothLogging: Sendable {
    
    private(set) static var isEnabled = true
    
    private static let disabledLogger = Logger(OSLog.disabled)
    
    public static func setEnabled(_ isEnabled: Bool) {
        Self.isEnabled = isEnabled
    }
    
    static func createLogger(for category: String) -> Logger {
        guard Self.isEnabled else { return Self.disabledLogger }
        
        return Logger(
            subsystem: Bundle(for: CentralManager.self).bundleIdentifier ?? "",
            category: category
        )
    }
}
