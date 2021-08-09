import Foundation
import os.log

public struct AsyncBluetooth {
    static let commonLogger = Logger(
        subsystem: Bundle(for: CentralManager.self).bundleIdentifier ?? "",
        category: "common"
    )
}
