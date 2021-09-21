import Foundation

enum ScanState {
    case notScanning
    case awaiting
    case scanning(continuation: AsyncStream<ScanData>.Continuation)
}
