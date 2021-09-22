//  Copyright (c) 2021 Manuel Fernandez-Peix Perez. All rights reserved.

import Foundation

struct CallbackUtils {
    static func result<T>(for value: T, error: Error?) -> Result<T, Error> {
        let result: Result<T, Error>
        
        if let error = error {
            result = .failure(error)
        } else {
            result = .success(value)
        }
        
        return result
    }
}
