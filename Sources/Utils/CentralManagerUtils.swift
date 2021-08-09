import Foundation
import CoreBluetooth

struct CentralManagerUtils {
    static func isBluetoothReady(_ bluetoothState: CBManagerState) -> Result<Void, Error>? {
        guard let isBluetoothReady: Bool = Self.isBluetoothReady(bluetoothState) else {
            return nil
        }
        return isBluetoothReady
            ? .success(())
            : .failure(BluetoothError.bluetoothUnavailable)
    }
    
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
