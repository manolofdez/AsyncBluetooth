# AsyncBluetooth
A small library that adds concurrency to CoreBluetooth APIs.

## Features
- Async/Await APIs
- Queueing of commands
- Data conversion to common types
- Thread safety
- Convenience APIs for reading/writing without needing to explicitly discover characteristics.
- Convenience API for waiting until Bluetooth is ready.

## Usage

### Scanning for a peripheral

Start scanning by calling the central manager's `scanForPeripherals` 
function. It returns an `AsyncStream` you can use to iterate over the 
discovered peripherals. Once you're satisfied with your scan, you can 
break from the loop and stop scanning.

```swift
let centralManager = CentralManager()

try await centralManager.waitUntilReady()

let scanDataStream = try await centralManager.scanForPeripherals(withServices: nil)
for await scanData in scanDataStream {
    // Check scan data...
}

await centralManager.stopScan()
```
### Connecting to a peripheral

Once you have your peripheral, you can use the central manager to connect 
to it. Note you must hold a reference to the Peripheral while it's 
connected.

```swift
try await centralManager.connect(peripheral, options: nil)
```

### Subscribe to central manager events

The central manager publishes several events. You can subscribe to them by using the `eventPublisher`.

```swift
centralManager.eventPublisher
    .sink {
        switch $0 {
        case .didConnectPeripheral(let peripheral):
            print("Connected to \(peripheral.identifier)")
        default:
            break
        }
    }
    .store(in: &cancellables)
```

See [CentralManagerEvent](Sources/CentralManager/CentralManagerEvent.swift) to see available events.


### Read value from characteristic

You can use convenience functions for reading characteristics. They will find the characteristic by using a `UUID`, and 
parse the data into the appropriate type.

```swift
let value: String? = try await peripheral.readValue(
    forCharacteristicWithUUID: UUID(uuidString: "")!,
    ofServiceWithUUID: UUID(uuidString: "")!
)

```

### Write value to characteristic

Similar to reading, we have convenience functions for writing to characteristics.

```swift
try await peripheral.writeValue(
    value,
    forCharacteristicWithUUID: UUID(uuidString: "")!,
    ofServiceWithUUID: UUID(uuidString: "")!
)

```

### Subscribe to a characteristic

To get notified when a characteristic's value is updated, we provide a publisher you can subscribe to:

```swift
let characteristicUUID = CBUUID()
peripheral.characteristicValueUpdatedPublisher
    .filter { $0.characteristic.uuid == characteristicUUID }
    .map { try? $0.parsedValue() as String? } // replace `String?` with your type
    .sink { value in
        print("Value updated to '\(value)'")
    }
    .store(in: &cancellables)
```

Remember that you should enable notifications on that characteristic to receive updated values.

```swift
try await peripheral.setNotifyValue(true, characteristicUUID, serviceUUID)
```

### Canceling operations

To cancel a specific operation, you can wrap your call in a `Task`:

```swift
let fetchTask = Task {
    do {
        return try await peripheral.readValue(
            forCharacteristicWithUUID: UUID(uuidString: "")!,
            ofServiceWithUUID: UUID(uuidString: "")!
        )
    } catch {
        return ""
    }
}

fetchTask.cancel()
```

There might also be cases were you want to stop awaiting for all responses. For example, when bluetooth has been powered off. This can be done like so:

```swift
centralManager.eventPublisher
    .sink {
        switch $0 {
        case .didUpdateState(let state):
            guard state == .poweredOff else {
                return
            }
            centralManager.cancelAllOperations()
            peripheral.cancelAllOperations()
        default:
            break
        }
    }
    .store(in: &cancellables)
```

### Logging

The library uses `os.log` to provide logging for several operations. These logs are enabled by default. If you wish to disable them, you can do:

```
AsyncBluetoothLogging.setEnabled(false)
```

## Examples

You can find practical, tasty recipes for how to use `AsyncBluetooth` in the 
[AsyncBluetooth Cookbook](https://github.com/manolofdez/AsyncBluetoothCookbook).

## Installation

### Swift Package Manager

This library can be installed using the Swift Package Manager by adding it 
to your Package Dependencies.

## Requirements

- iOS 14.0+
- MacOS 11.0+
- Swift 5
- Xcode 13.2.1+

## License

Licensed under MIT license.
