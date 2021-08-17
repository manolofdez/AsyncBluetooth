import Foundation

struct TestUtils {
    @discardableResult
    static func performDelayed(
        timeInterval: TimeInterval = 0,
        block: @escaping () -> Void
    ) -> Task<Void, Error> {
        Task {
            Thread.sleep(forTimeInterval: timeInterval)
            block()
        }
    }
}
