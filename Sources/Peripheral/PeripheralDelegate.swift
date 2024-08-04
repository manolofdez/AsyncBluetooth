//  Copyright (c) 2023 Manuel Fernandez-Peix Perez. All rights reserved.

import Foundation
import CoreBluetooth
import os.log

final class PeripheralDelegate: NSObject, Sendable {
    
    private static var logger: Logger {
        Logging.logger(for: "peripheralDelegate")
    }

    let context = PeripheralContext()
}

// MARK: CBPeripheralDelegate

extension PeripheralDelegate: CBPeripheralDelegate {
    func peripheral(_ cbPeripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: RSSI, error: error)
                try await self.context.readRSSIExecutor.setWorkCompletedWithResult(result)
            } catch {
                Self.logger.error("Received ReadRSSI response without a continuation")
            }
        }
    }
    
    func peripheral(_ cbPeripheral: CBPeripheral, didDiscoverServices error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.context.discoverServiceExecutor.setWorkCompletedWithResult(result)
            } catch {
                Self.logger.warning("Received DiscoverServices response without a continuation")
            }
        }
    }
    
    func peripheral(_ cbPeripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.context.discoverIncludedServicesExecutor.setWorkCompletedForKey(
                    service.uuid, result: result
                )
            } catch {
                Self.logger.warning("Received DiscoverIncludedServices response without a continuation")
            }
        }
    }
    
    func peripheral(_ cbPeripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.context.discoverCharacteristicsExecutor.setWorkCompletedForKey(
                    service.uuid, result: result
                )
            } catch {
                Self.logger.warning("Received DiscoverCharacteristics result without a continuation")
            }
        }
    }
    
    func peripheral(_ cbPeripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        Task {
            if characteristic.isNotifying {
               // characteristic.value is Data() and it will get trampled if allowed to run async.
               await self.context.characteristicValueUpdatedSubject.send( Characteristic(characteristic) )
            }

            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.context.readCharacteristicValueExecutor.setWorkCompletedForKey(
                    characteristic.uuid, result: result
                )
            } catch {
                guard !characteristic.isNotifying else { return }
                Self.logger.warning("Received UpdateValue result for characteristic without a continuation")
            }
        }
    }
    
    func peripheral(_ cbPeripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.context.writeCharacteristicValueExecutor.setWorkCompletedForKey(
                    characteristic.uuid, result: result
                )
            } catch {
                Self.logger.warning("Received WriteValue result for characteristic without a continuation")
            }
        }
    }
    
    func peripheral(
        _ cbPeripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.context.setNotifyValueExecutor.setWorkCompletedForKey(
                    characteristic.uuid, result: result
                )
            } catch {
                Self.logger.warning("Received UpdateNotificationState result without a continuation")
            }
        }
    }
    
    func peripheral(
        _ cbPeripheral: CBPeripheral,
        didDiscoverDescriptorsFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.context.discoverDescriptorsExecutor.setWorkCompletedForKey(
                    characteristic.uuid, result: result
                )
            } catch {
                Self.logger.warning("Received DiscoverDescriptors result without a continuation")
            }
        }
    }
    
    func peripheral(_ cbPeripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.context.readDescriptorValueExecutor.setWorkCompletedForKey(
                    descriptor.uuid, result: result
                )
            } catch {
                Self.logger.warning("Received UpdateValue result for descriptor without a continuation")
            }
        }
    }
    
    func peripheral(_ cbPeripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: (), error: error)
                try await self.context.writeDescriptorValueExecutor.setWorkCompletedForKey(
                    descriptor.uuid, result: result
                )
            } catch {
                Self.logger.warning("Received WriteValue result for descriptor without a continuation")
            }
        }
    }
    
    func peripheral(_ cbPeripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {
        Task {
            do {
                let result = CallbackUtils.result(for: channel, error: error)
                try await self.context.openL2CAPChannelExecutor.setWorkCompletedWithResult(result)
            } catch {
                Self.logger.warning("Received OpenChannel result without a continuation")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        Task {
            await self.context.invalidatedServicesSubject.send(invalidatedServices.map { Service($0) })
        }
    }
}
