import Foundation
import CoreBluetooth

protocol CBCentralManaging: AnyObject {
    var delegate: CBCentralManagerDelegate? { get set }
    var isScanning: Bool { get }
    
    func scanForPeripherals(withServices serviceUUIDs: [CBUUID]?, options: [String : Any]?)
    func stopScan()
    
    // TODO: Implement
    
//    open class func supports(_ features: CBCentralManager.Feature) -> Bool
//    open func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBPeripheral]
//    open func retrieveConnectedPeripherals(withServices serviceUUIDs: [CBUUID]) -> [CBPeripheral]
//    open func connect(_ peripheral: CBPeripheral, options: [String : Any]? = nil)
//    open func cancelPeripheralConnection(_ peripheral: CBPeripheral)
//    open func registerForConnectionEvents(options: [CBConnectionEventMatchingOption : Any]? = nil)
}

