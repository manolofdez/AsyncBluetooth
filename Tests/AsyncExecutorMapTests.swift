import Foundation
import XCTest
@testable import AsyncBluetooth

class AsyncExecutorMapTests: XCTestCase {
    
    /// Validates that two concurrent tasks won't block on waiting for the continuation to complete.
    func testCanPerformTwoTasksSimultaneously() async {
        class State {
            var isExecutingTask1 = false
            var isExecutingTask2 = false
        }

        let executor = AsyncExecutorMap<String, Void>()
        let state = State()
        
        Task {
            try? await executor.enqueue(withKey: "task1") {
                state.isExecutingTask1 = true
            }
        }
        
        Task {
            try? await executor.enqueue(withKey: "task2") {
                state.isExecutingTask2 = true
            }
        }
        
        let testTask = Task {
            XCTAssert(state.isExecutingTask1)
            XCTAssert(state.isExecutingTask2)
            
            Task {
                try await executor.setWorkCompletedForKey("task1", result: .success(()))
                try await executor.setWorkCompletedForKey("task2", result: .success(()))
            }
        }
        
        let _ = await testTask.result
    }    
}
