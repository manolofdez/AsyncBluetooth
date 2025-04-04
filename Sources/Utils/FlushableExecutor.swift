// Copyright (c) 2023 Manuel Fernandez. All rights reserved.

import Foundation
 
protocol FlushableExecutor where Self: Actor {
    /// Sends an error to all queued and executing work.
    func flush(error: Error) async
}
