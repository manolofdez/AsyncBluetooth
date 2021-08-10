import Foundation

public enum BluetoothError: Error {
    case bluetoothUnavailable
    case scanningInProgress
    case connectingInProgress
    case errorConnectingToPeripheral(error: Error?)
}
