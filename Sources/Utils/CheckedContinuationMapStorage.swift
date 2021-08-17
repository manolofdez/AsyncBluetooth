import Foundation

/// Actor that provides a safe way to add to and resume checked continuations by an identifier (key).
actor CheckedContinuationMapStorage<K, V, E> where K: Hashable, E: Error {
    
    enum Error: Swift.Error {
        case continuationAlreadyExistsForKey(key: K)
        case continuationNotFound
    }
    
    private var continuations: [K: CheckedContinuation<V, E>] = [:]
    
    func addContinuation(_ continuation: CheckedContinuation<V, E>, forKey key: K) throws {
        guard !self.contains(key: key) else {
            throw Error.continuationAlreadyExistsForKey(key: key)
        }
        self.continuations[key] = continuation
    }
    
    /// Resumes the continuation with the given key and removes it from the map.
    func resumeContinuation(_ result: Result<V, E>, withKey key: K) throws {
        guard let continuation = self.continuations.removeValue(forKey: key) else {
            throw Error.continuationNotFound
        }
        continuation.resume(with: result)
    }
    
    private func contains(key: K) -> Bool {
        self.continuations.contains { currentKey, currentContinuation in
            key == currentKey
        }
    }
}

extension CheckedContinuationMapStorage where E == Swift.Error {
    /// Adds a new continuation, and performs the given block.
    /// - Note: The continuation is not resumed.
    func perform(
        withKey key: K,
        block: @escaping () -> Void
    ) async throws -> V {
        try await withCheckedThrowingContinuation { continuation in
            do {
                try self.addContinuation(continuation, forKey: key)
            } catch {
                continuation.resume(throwing: error)
                return
            }
            block()
        }
    }
}
