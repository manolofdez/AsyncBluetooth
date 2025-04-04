//  Copyright (c) 2021 Manuel Fernandez-Peix Perez. All rights reserved.

import Foundation
import os.log

/// Executes work in parallel when keys are different, and serially when there's work queued for a given key.
/// After work for a given key has started, this class will await until the client completes it before taking
/// on the next work for that key.
actor AsyncExecutorMap<Key, Value> where Key: Hashable {
    
    private static var logger: Logger {
        Logging.logger(for: "asyncExecuterMap")
    }
    
    enum AsyncExecutorMapError: Error {
        case executorNotFound
    }
    
    private var executors: [Key: AsyncSerialExecutor<Value>] = [:]
    
    /// Places work in the queue for the given key to be executed. If the queue is empty it will be executed.
    /// Otherwise it will get dequeued (and executed) when all previously queued work has finished.
    /// - Note: Once the block is executed, the task will be waiting until clients provide a Result via
    ///         `setWorkCompletedForKey`. No other work will be executed during this time.
    func enqueue(
        withKey key: Key,
        _ block: @escaping () -> Void
    ) async throws -> Value {
        let executor = self.executors[key] ?? {
            let executor = AsyncSerialExecutor<Value>()
            self.executors[key] = executor
            return executor
        }()

        return try await executor.enqueue(block)
    }
    
    /// Completes the current work for the given key.
    func setWorkCompletedForKey(_ key: Key, result: Result<Value, Error>) async throws {
        guard let executor = self.executors[key] else {
            throw AsyncExecutorMapError.executorNotFound
        }
        
        try await executor.setWorkCompletedWithResult(result)
        
        guard await !executor.hasWork else { return }
        
        self.executors[key] = nil
    }
    
    /// Sends the given result to all queued and executing work from the given key.
    func flush(key: Key, result: Result<Value, Error>) async throws {
        guard let executor = self.executors[key] else {
            throw AsyncExecutorMapError.executorNotFound
        }

        await executor.flush(result)
        
        guard await !executor.hasWork else { return }
        
        self.executors[key] = nil
    }
    
    func hasWorkForKey(_ key: Key) async -> Bool {
        await self.executors[key]?.hasWork == true
    }
}

extension AsyncExecutorMap: FlushableExecutor {
    func flush(error: Error) async {
        for key in self.executors.keys {
            do {
                try await self.flush(key: key, result: .failure(error))
            } catch {
                Self.logger.warning("Unable to flush executor with key: \("\(key)").")
            }
        }
    }
}
