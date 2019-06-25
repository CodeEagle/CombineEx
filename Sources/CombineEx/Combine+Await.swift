import Combine
import Foundation

extension Publisher {
    public func await() throws -> Output {
        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<Output, Failure>?
        let proQueue: DispatchQueue = .init(label: "all.property", attributes: .concurrent)
        discardableSink(onValue: { (value) in
            proQueue.async(flags: .barrier) { result = .success(value) }
            
        }, onCompletion: { info in
            switch info {
            case let .failure(e): proQueue.async(flags: .barrier) { result = .failure(e) }
            case .finished: break
            }
            semaphore.signal()
        })
        semaphore.wait()
        if  let r = proQueue.sync(execute: { result }) {
            switch r {
            case let .failure(e): throw e
            case let .success(v): return v
            }
        }
        throw AwaitError.unknown
    }
}
