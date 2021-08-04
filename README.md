# AsyncYerBlueTooth
Offers concurrency wrapper around CoreBluetooth

## Uses

Scanning for peripherals

```swift
let centralManager = CentralManager()
let peripheral: Peripheral

for await peripheralScanData in peripheralScanStream.scanForPeripherals() {
    guard peripheralScanData.peripheral.name == NAME_OF_PERIPHERAL else {
        continue
    }
    peripheral = peripheralScanData.peripheral
    peripheralScanStream.stopScan()
    break
}
```
