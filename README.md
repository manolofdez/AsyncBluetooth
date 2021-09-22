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

var scanDataStream = try await centralManager.scanForPeripherals(withServices: nil)
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

### Read value from characteristic

You can use convenience functions for reading and writing to characteristics. They will find the characteristic by using a `UUID`, and 
parse the data into the appropriate type.

```swift
let value: String? = try await peripheral.readValue(
	forCharacteristicWithUUID: UUID(uuidString: "")!,
	ofServiceWithUUID: UUID(uuidString: "")!
)

```

## Installation

### Swift Package Manager

This library can be installed using the Swift Package Manager by adding it 
to your Package Dependencies.

## Requirements

- iOS 15.0+
- MacOS 12.0+
- Swift 5

## License

Licensed under MIT license.