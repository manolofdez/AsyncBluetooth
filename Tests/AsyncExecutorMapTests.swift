import Foundation
import XCTest
@testable import AsyncBluetooth

class AsyncExecutorMapTests: XCTestCase {
    
    /// Validates that two concurrent tasks won't block on waiting for the continuation to complete.
    func testCanPerformTwoTasksSimultaneously() async {
        class State {
            var isExecutingTask1 = false
        }
        
        let executor = AsyncExecutorMap<String, Void>()
        let state = State()
        
        XCTAssert(!state.isExecutingTask1)
        
        Task {
            try? await executor.enqueue(withKey: "task1") {
                state.isExecutingTask1 = true
            }
        }
        
        let task2 = Task {
            try? await executor.enqueue(withKey: "task2") {
                XCTAssert(state.isExecutingTask1)
                
                Task {
                    try? await executor.setWorkCompletedForKey("task2", result: .success(()))
                }
            }
        }
        
        _ = await task2.result
    }
}
