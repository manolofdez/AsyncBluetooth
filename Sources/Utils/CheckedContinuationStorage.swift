import Foundation

/// Provides a safe way to set and resume a continuation.
actor CheckedContinuationStorage<T, E> where E: Error {
    
    enum Error: Swift.Error {
        case continuationAlreadySet
        case continuationNotFound
    }
    
    private var continuation: CheckedContinuation<T, E>?
    
    func setContinuation(_ continuation: CheckedContinuation<T, E>) throws {
        guard self.continuation == nil else {
            throw Error.continuationAlreadySet
        }
        self.continuation = continuation
    }
    
    /// Resumes and clears the continuation.
    func resume(_ result: Result<T, E>) throws {
        guard let continuation = continuation else {
            throw Error.continuationNotFound
        }
        continuation.resume(with: result)
        self.continuation = nil
    }
}

extension CheckedContinuationStorage where E == Swift.Error {
    /// Sets a new continuation, and performs the given block.
    /// - Note: The continuation is not resumed.
    func perform(block: @escaping () -> Void) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try self.setContinuation(continuation)
            } catch {
                continuation.resume(throwing: error)
                return
            }
            block()
        }
    }
}
