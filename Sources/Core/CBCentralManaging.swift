import Foundation
import CoreBluetooth

/// Protocol defining an object that scans for, discovers, connects to, and manages peripherals. It's modeled after
/// `CBCentralManager` and is used for mocking its behavior during testing.
protocol CBCentralManaging: AnyObject {
    var delegate: CBCentralManagerDelegate? { get set }
    var state: CBManagerState { get }
    var isScanning: Bool { get }
    
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]?)
    func stopScan()
    func connect(_ peripheral: Peripheral, options: [String : Any]?)
    
    // TODO: Implement
    
//    open class func supports(_ features: CBCentralManager.Feature) -> Bool
//    open func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBPeripheral]
//    open func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [CBPeripheral]
//    open func cancelPeripheralConnection(_ peripheral: CBPeripheral)
//    open func registerForConnectionEvents(options: [CBConnectionEventMatchingOption : Any]? = nil)
}

