import Foundation

/// Actor that provides a safe way to add to and resume a list of checked continuations.
actor CheckedContinuationListStorage<T, E> where E: Error {
    
    private var continuations: [CheckedContinuation<T, E>] = []
    
    func append(_ continuation: CheckedContinuation<T, E>) {
        self.continuations.append(continuation)
    }
    
    /// Resumes all continuations with the given result and clears the continuation list.
    func resumeAll(_ result: Result<T, E>) {
        self.continuations.forEach { $0.resume(with: result) }
        self.continuations = []
    }
}
