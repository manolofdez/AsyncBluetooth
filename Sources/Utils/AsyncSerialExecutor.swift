import Foundation

/// Executes queued work serially, in the order they where added (FIFO). After work has started, this class will await
/// until the client completes it before taking on the next work.
actor AsyncSerialExecutor<Value> {
    
    enum AsyncSerialExecutor: Error {
        case continuationNotFound
        case canceled
        case executorDeinitialized
    }
    
    private struct QueuedWork {
        let id: UUID
        let block: () -> Void
        let continuation: CheckedContinuation<Value, Error>
        var isCanceled = false
    }
    
    var isExecutingWork: Bool {
        self.currentContinuation != nil
    }
    
    var hasWork: Bool {
        self.isExecutingWork || self.queue.count > 0
    }
    
    private var currentContinuation: CheckedContinuation<Value, Error>?
    private var queue: [QueuedWork] = []
    
    /// Places work in the queue to be executed. If the queue is empty it will be executed. Otherwise it will
    /// get dequeued (and executed) when all previously queued work has finished.
    /// - Note: Once the block is executed, the task will be waiting until clients provide a Result via
    ///         `setWorkCompletedWithResult`. No other work will be executed during this time.
    func enqueue(
        _ block: @escaping () -> Void
    ) async throws -> Value {
        let queuedWorkID = UUID()
        
        return try await withTaskCancellationHandler {
            Task { [weak self] in
                await self?.cancelQueuedWork(id: queuedWorkID)
            }
        } operation: {
            try await withCheckedThrowingContinuation { continuation in
                self.queue.append(QueuedWork(id: queuedWorkID, block: block, continuation: continuation))
                self.dequeueIfNecessary()
            }
        }
    }
    
    /// Completes the current work with the given result and dequeues the next queued work.
    func setWorkCompletedWithResult(_ result: Result<Value, Error>) throws {
        defer {
            self.scheduleDequeue()
        }
        
        guard let continuation = self.currentContinuation else {
            throw AsyncSerialExecutor.continuationNotFound
        }
        continuation.resume(with: result)
        
        self.currentContinuation = nil
    }
    
    /// Sends the given result to all queued and executing work.
    func flush(_ result: Result<Value, Error>) {
        let queue = self.queue
        self.queue.removeAll()
        
        self.currentContinuation?.resume(with: result)
        queue.forEach { $0.continuation.resume(with: result) }
    }
    
    private func scheduleDequeue() {
        Task {
            self.dequeueIfNecessary()
        }
    }
    
    /// Grabs the next available work from the queue. If it's not canceled, executes it. Otherwise sends a
    /// `AsyncBlockQueueError.canceled` error.
    private func dequeueIfNecessary() {
        guard !self.isExecutingWork && !self.queue.isEmpty else { return }
        
        let queuedWork = self.queue.removeFirst()
        
        guard !queuedWork.isCanceled else {
            queuedWork.continuation.resume(throwing: AsyncSerialExecutor.canceled)
            self.scheduleDequeue()
            return
        }
        
        self.currentContinuation = queuedWork.continuation
        
        queuedWork.block()
    }

    /// Marks a Queued Work as canceled. Once the work gets dequeued, it will get canceled without executing.
    /// - Note: If the work is already executing it will NOT get canceled.
    private func cancelQueuedWork(id: UUID) {
        guard let index =  self.queue.firstIndex(where: { $0.id == id }) else {
            return
        }
        self.queue[index].isCanceled = true
    }
    
    deinit {
        if !self.queue.isEmpty {
            AsyncBlockQueueConstants.logger.warning("AsyncBlockQueue deinitialized with pending work.")
        }
        
        if self.isExecutingWork {
            AsyncBlockQueueConstants.logger.warning("AsyncBlockQueue deinitialized while executing work.")
        }
        
        self.flush(.failure(AsyncSerialExecutor.executorDeinitialized))
    }
}
