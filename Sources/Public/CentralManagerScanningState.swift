import Foundation

enum CentralManagerScanningState {
    case notScanning
    case awaiting
    case scanning(continuation: AsyncStream<PeripheralScanData>.Continuation)
}
