// Copyright (c) 2023 Manuel Fernandez. All rights reserved.

import Foundation

actor ThreadSafeArray<Element> {
    
    private var array: [Element]
    
    init(array: [Element] = []) {
        self.array = array
    }
    
    nonisolated func append(_ element: Element) {
        Task {
            await self.append(element)
        }
    }
    
    func append(_ element: Element) async {
        array.append(element)
    }
}

extension ThreadSafeArray: AsyncSequence {
    struct AsyncIterator: AsyncIteratorProtocol {
        private let threadSafeArray: ThreadSafeArray
        private var iterator: Array<Element>.Iterator?
        
        init(threadSafeArray: ThreadSafeArray) {
            self.threadSafeArray = threadSafeArray
        }

        mutating func next() async throws -> Element? {
            if iterator == nil {
                iterator = await threadSafeArray.array.makeIterator()
            }
            return iterator?.next()
        }
    }

    nonisolated func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(threadSafeArray: self)
    }
}

extension ThreadSafeArray: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: Element...) {
        self.init(array: elements)
    }
}
