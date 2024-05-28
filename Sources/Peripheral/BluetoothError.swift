//  Copyright (c) 2021 Manuel Fernandez-Peix Perez. All rights reserved.

import Foundation

public enum BluetoothUnavailableReason {
    case poweredOff
    case unauthorized
    case unsupported
    case unknown
}

public enum BluetoothError: Error {
    case invalidUUID
    case bluetoothUnavailable(BluetoothUnavailableReason)
    case connectingInProgress
    case disconnectingInProgress
    case cancelledConnectionToPeripheral
    case errorConnectingToPeripheral(error: Error?)
    case characteristicNotFound
    case unableToParseCharacteristicValue
    case unableToConvertValueToData
    case noConnectionToPeripheralExists
    case operationCancelled
}
