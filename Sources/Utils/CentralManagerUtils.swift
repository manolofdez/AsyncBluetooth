import Foundation
import CoreBluetooth

/// General helper functions used by the Central Manager.
struct CentralManagerUtils {
    
    /// Whether Bluetooth is ready to be used or not given a bluetoothState.
    /// - Returns: success when `poweredOn`; failure when `unsupported`, `unauthorized` or `poweredOff`; and
    ///            nil for `unknown` or `resetting`.
    static func isBluetoothReady(_ bluetoothState: CBManagerState) -> Result<Void, Error>? {
        guard let isBluetoothReady: Bool = Self.isBluetoothReady(bluetoothState) else {
            return nil
        }
        return isBluetoothReady
            ? .success(())
            : .failure(BluetoothError.bluetoothUnavailable)
    }
    
    /// Whether Bluetooth is ready to be used or not given a bluetoothState.
    /// - Returns: true when `poweredOn`; false when `unsupported`, `unauthorized` or `poweredOff`; and
    ///            nil for `unknown` or `resetting`.
    private static func isBluetoothReady(_ bluetoothState: CBManagerState) -> Bool? {
        switch bluetoothState {
        case .poweredOn:
            return true
        case .unsupported, .unauthorized, .poweredOff:
            return false
        case .unknown, .resetting:
            return nil
        @unknown default:
            AsyncBluetooth.commonLogger.error("Unsupported CBManagerState received with raw value of \(bluetoothState.rawValue)")
            return false
        }
    }
}
