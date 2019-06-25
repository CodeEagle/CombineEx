import Combine
import Dispatch

public func race<Value, Failure>(_ promises: AnyPublisher<Value, Failure>..., on queue: DispatchQueue = .main) -> AnyPublisher<Value, Failure> where Failure: Error {
    race(promises)
}

public func race<Value, Failure>(_ promises: [AnyPublisher<Value, Failure>], on queue: DispatchQueue = .main) -> AnyPublisher<Value, Failure> where Failure: Error {
    .init { (completion) in
        queue.async {
            let proQueue: DispatchQueue = .init(label: "race.property", attributes: .concurrent)
            var firstValue: Result<Value, Failure>?
            for item in promises {
                // return early when already has value
                guard proQueue.sync(execute: { return firstValue }) == nil else { return }
                
                item.discardableSink(onValue: { value in
                    guard proQueue.sync(execute: { return firstValue }) == nil else { return }
                    proQueue.async(flags: .barrier) { firstValue = .success(value) }
                    
                    _ = completion.receive(value)
                    completion.receive(completion: .finished)
                }, onCompletion: { info in
                    guard proQueue.sync(execute: { return firstValue }) == nil else { return }
                    
                    switch info {
                    case let .failure(e):
                        proQueue.async(flags: .barrier) { firstValue = .failure(e) }
                        completion.receive(completion: .failure(e))
                        
                    case .finished: break
                    }
                })
            }
        }
    }
}
