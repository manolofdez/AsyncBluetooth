// Copyright (c) 2022 Manuel Fernandez. All rights reserved.

import Foundation
import CoreBluetooth

public enum CentralManagerEvent {
    case didUpdateState(state: CBManagerState)
    case willRestoreState(state: [String: Any])
    case didConnectPeripheral(peripheral: AsyncPeripheral)
    case didDisconnectPeripheral(peripheral: AsyncPeripheral, error: Error?)
}
