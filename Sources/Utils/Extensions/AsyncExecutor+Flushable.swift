// Copyright (c) 2023 Manuel Fernandez. All rights reserved.

import Foundation

extension AsyncSerialExecutor: FlushableExecutor {
    func flush(error: Error) async throws {
        self.flush(.failure(error))
    }
}
