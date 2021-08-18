import Foundation

public enum BluetoothError: Error {
    case bluetoothUnavailable
    case scanningInProgress
    case connectingInProgress
    case disconnectingInProgress
    case errorConnectingToPeripheral(error: Error?)
    case characteristicNotFound
    case unableToParseCharacteristicValue
}
