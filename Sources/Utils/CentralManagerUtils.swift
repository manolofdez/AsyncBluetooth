//  Copyright (c) 2021 Manuel Fernandez-Peix Perez. All rights reserved.

import Foundation
import CoreBluetooth

/// General helper functions used by the Central Manager.
struct CentralManagerUtils {
    
    /// Whether Bluetooth is ready to be used or not given a bluetoothState.
    /// - Returns: success when `poweredOn`; failure when `unsupported`, `unauthorized` or `poweredOff`; and
    ///            nil for `unknown` or `resetting`.
    static func isBluetoothReady(_ bluetoothState: CBManagerState) -> Result<Void, Error>? {
        guard bluetoothState != .poweredOn else {
            return .success(())
        }

        guard let reason = BluetoothUnavailableReason(bluetoothState) else {
            return nil
        }

        return .failure(BluetoothError.bluetoothUnavailable(reason))
    }
}

private extension BluetoothUnavailableReason {
    init?(_ bluetoothState: CBManagerState) {
        switch bluetoothState {
        case .unauthorized:
            self = .unauthorized
        case .unsupported:
            self = .unsupported
        case .poweredOff:
            self = .poweredOff
        case .poweredOn, .unknown, .resetting:
            return nil
        @unknown default:
            AsyncBluetooth.commonLogger.error("Unsupported CBManagerState received with raw value of \(bluetoothState.rawValue)")
            self = .unknown
        }
    }
}
