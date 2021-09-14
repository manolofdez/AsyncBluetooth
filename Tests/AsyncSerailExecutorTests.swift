import Foundation
import XCTest
@testable import AsyncBluetooth

class AsyncSerailExecutorTests: XCTestCase {
    
    class State {
        class TaskState {
            var executed = false
            var isComplete = false
        }
        var taskStates: [TaskState] = []
    }
    
    func testExecutesTasksSerially() async {
        let state = State()
        let queue = AsyncSerialExecutor<Void>()
        
        let task1 = Self.enqueueTask(on: queue, state: state)
        Self.enqueueTask(on: queue, state: state)
        
        XCTAssert(!state.taskStates[0].executed)
        XCTAssert(!state.taskStates[1].executed)
        
        Task {
            XCTAssert(state.taskStates[0].executed)
            XCTAssert(!state.taskStates[1].executed)
            
            try await queue.setWorkCompletedWithResult(.success(()))
        }

        await _ = task1.result

        XCTAssert(state.taskStates[0].executed)
        XCTAssert(state.taskStates[1].executed)
    }
    
    func testCanceledTasksDontExecute() async throws {
        let state = State()
        let queue = AsyncSerialExecutor<Void>()
        
        Self.enqueueTask(on: queue, state: state)
        let task2 = Self.enqueueTask(on: queue, state: state)

        task2.cancel()

        Task {
            try await queue.setWorkCompletedWithResult(.success(()))
        }
        
        await _ = task2.result
        
        XCTAssert(state.taskStates[0].executed)
        XCTAssert(state.taskStates[0].isComplete)
        
        XCTAssert(!state.taskStates[1].executed)
        XCTAssert(state.taskStates[1].isComplete)
    }
    
    func testCanceledTasksContinueExecutingNextTask() async throws {
        let state = State()
        let queue = AsyncSerialExecutor<Void>()
        
        Self.enqueueTask(on: queue, state: state)
        let task2 = Self.enqueueTask(on: queue, state: state)
        Self.enqueueTask(on: queue, state: state)

        task2.cancel()

        Task {
            try await queue.setWorkCompletedWithResult(.success(()))
        }
        
        await _ = task2.result
        
        XCTAssert(!state.taskStates[1].executed)
        XCTAssert(state.taskStates[1].isComplete)
        
        XCTAssert(state.taskStates[2].executed)
        XCTAssert(!state.taskStates[2].isComplete)
    }

    
    @discardableResult
    private static func enqueueTask(
        on queue: AsyncSerialExecutor<Void>,
        state: State
    ) -> Task<Void, Error> {
        let taskState = State.TaskState()
        state.taskStates.append(taskState)
        
        return Task {
            try? await queue.enqueue {
                taskState.executed = true
            }
            taskState.isComplete = true
        }
    }
}
