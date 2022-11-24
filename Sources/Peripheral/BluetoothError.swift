//  Copyright (c) 2021 Manuel Fernandez-Peix Perez. All rights reserved.

import Foundation

public enum BluetoothError: Error {
    case bluetoothUnavailable
    case connectingInProgress
    case disconnectingInProgress
    case cancelledConnectionToPeripheral
    case errorConnectingToPeripheral(error: Error?)
    case characteristicNotFound
    case unableToParseCharacteristicValue
    case unableToConvertValueToData
    case noConnectionToPeripheralExists
}
