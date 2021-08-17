import Foundation
import XCTest
@testable import AsyncBluetooth

class CheckedContinuationMapStorageTests: XCTestCase {
    
    /// Validates that two concurrent tasks won't block on waiting for the continuation to complete.
    func testCanPerformTwoTasksSimultaneously() async {
        class State {
            var isExecutingTask1 = false
            var isExecutingTask2 = false
        }

        let storage = CheckedContinuationMapStorage<String, Void, Error>()
        let state = State()
        
        let task1 = Task {
            try? await storage.perform(withKey: "task1") {
                state.isExecutingTask1 = true
            }
        }
        
        let task2 = Task {
            try? await storage.perform(withKey: "task2") {
                state.isExecutingTask2 = true
            }
        }
        
        TestUtils.performDelayed() {
            XCTAssert(state.isExecutingTask1)
            XCTAssert(state.isExecutingTask2)
            
            Task {
                try await storage.resumeContinuation(.success(()), withKey: "task1")
                try await storage.resumeContinuation(.success(()), withKey: "task2")
            }
        }
        
        let _ = await task1.value
        let _ = await task2.value
    }    
}
