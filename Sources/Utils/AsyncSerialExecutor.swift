//  Copyright (c) 2021 Manuel Fernandez-Peix Perez. All rights reserved.

import Foundation

/// Executes queued work serially, in the order they where added (FIFO). After work has started, this class will await
/// until the client completes it before taking on the next work.
actor AsyncSerialExecutor<Value> {
    
    typealias Constants = AsyncSerialExecutorConstants
    
    enum AsyncSerialExecutor: Error {
        case notExecutingWork
        case canceled
        case executorDeinitialized
    }
    
    private struct QueuedWork {
        let id: UUID
        let block: () -> Void
        let continuation: CheckedContinuation<Value, Error>
        var isCanceled = false
    }
    
    private struct CurrentWork {
        let id: UUID
        let continuation: CheckedContinuation<Value, Error>
    }
    
    var isExecutingWork: Bool {
        self.currentWork != nil
    }
    
    /// Whether we're executing or have queued work.
    var hasWork: Bool {
        self.isExecutingWork || self.queue.count > 0
    }
    
    private var currentWork: CurrentWork?
    private var queue: [QueuedWork] = []
    
    
    /// Places work in the queue to be executed. If the queue is empty it will be executed. Otherwise it will
    /// get dequeued (and executed) when all previously queued work has finished.
    /// This function will await until the given block is executed and will only resume after clients provide a Result
    /// via `setWorkCompletedWithResult`.
    /// - Note: No other work will be executed while there's a work in progress.
    func enqueue(
        _ block: @escaping () -> Void
    ) async throws -> Value {
        let queuedWorkID = UUID()
        
        return try await withTaskCancellationHandler {
            Task.detached { [weak self] in
                await self?.cancelWork(id: queuedWorkID)
            }
        } operation: {
            try await withCheckedThrowingContinuation { continuation in
                self.queue.append(QueuedWork(id: queuedWorkID, block: block, continuation: continuation))
                self.scheduleDequeue()
            }
        }
    }
    
    /// Completes the current work with the given result and dequeues the next queued work.
    func setWorkCompletedWithResult(_ result: Result<Value, Error>) throws {
        defer {
            self.scheduleDequeue()
        }
        
        guard let currentWork = self.currentWork else {
            throw AsyncSerialExecutor.notExecutingWork
        }
        
        currentWork.continuation.resume(with: result)
        
        self.currentWork = nil
    }
    
    /// Sends the given result to all queued and executing work.
    func flush(_ result: Result<Value, Error>) {
        let queue = self.queue
        self.queue.removeAll()
        
        self.currentWork?.continuation.resume(with: result)
        self.currentWork = nil
        
        queue.forEach { $0.continuation.resume(with: result) }
    }
    
    private func scheduleDequeue() {
        Task.detached {
            await self.dequeueIfNecessary()
        }
    }
    
    /// Grabs the next available work from the queue. If it's not canceled, executes it. Otherwise sends a
    /// `AsyncSerialExecutor.canceled` error.
    private func dequeueIfNecessary() {
        guard !self.isExecutingWork && !self.queue.isEmpty else { return }
        
        let queuedWork = self.queue.removeFirst()
        
        guard !queuedWork.isCanceled else {
            queuedWork.continuation.resume(throwing: AsyncSerialExecutor.canceled)
            self.scheduleDequeue()
            return
        }
        
        self.currentWork = CurrentWork(id: queuedWork.id, continuation: queuedWork.continuation)
        
        queuedWork.block()
    }

    /// Cancels the work with the given ID. If the work is executing it will be immediately canceled. If it's queued,
    /// the work will get flagged and once its dequeued, it will get canceled without executing.
    private func cancelWork(id: UUID) {
        guard let currentWork = self.currentWork, currentWork.id == id else {
            self.markQueuedWorkAsCanceled(id: id)
            return
        }
        currentWork.continuation.resume(throwing: AsyncSerialExecutor.canceled)
        self.currentWork = nil
        self.scheduleDequeue()
    }
    
    private func markQueuedWorkAsCanceled(id: UUID) {
        guard let index = self.queue.firstIndex(where: { $0.id == id }) else { return }
        self.queue[index].isCanceled = true
    }
    
    deinit {
        guard !self.queue.isEmpty || self.isExecutingWork else { return }
        
        if !self.queue.isEmpty {
            Constants.logger.warning("AsyncSerialExecutor deinitialized with pending work.")
        }
        
        if self.isExecutingWork {
            Constants.logger.warning("AsyncSerialExecutor deinitialized while executing work.")
        }
        
        self.flush(.failure(AsyncSerialExecutor.executorDeinitialized))
    }
}
