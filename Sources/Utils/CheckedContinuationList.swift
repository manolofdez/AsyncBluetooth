import Foundation

actor CheckedContinuationList<T, E> where E: Error {
    
    private var continuations: [CheckedContinuation<T, E>] = []
    
    func append(_ continuation: CheckedContinuation<T, E>) {
        self.continuations.append(continuation)
    }
    
    func resumeAll(_ result: Result<T, E>) {
        self.continuations.forEach { $0.resume(with: result) }
        self.continuations = []
    }
}
