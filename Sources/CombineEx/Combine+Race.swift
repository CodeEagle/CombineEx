import Combine
import Dispatch
import Foundation

public func race<Value, Failure>(_ promises: AnyPublisher<Value, Failure>..., on queue: DispatchQueue = .main) -> AnyPublisher<Value, Failure> where Failure: Error {
    race(promises)
}

public func race<Value, Failure>(_ promises: [AnyPublisher<Value, Failure>], on queue: DispatchQueue = .main) -> AnyPublisher<Value, Failure> where Failure: Error {
    .passThrough { (completion) in
        queue.async {
            let proQueue: DispatchQueue = .init(label: "race.property", attributes: .concurrent)
            var firstValue: Result<Value, Failure>?
            var tokens: [AnyCancellable] = []
            let id = UUID()
            for item in promises {
                // return early when already has value
                guard proQueue.sync(execute: { return firstValue }) == nil else { return }
                let token = item.sink(receiveCompletion: { info in
                    defer { TokenManager.shared.removeBox(by: id) }
                    guard proQueue.sync(execute: { return firstValue }) == nil else { return }

                    switch info {
                    case let .failure(e):
                        proQueue.async(flags: .barrier) { firstValue = .failure(e) }
                        completion.send(completion: .failure(e))

                    case .finished: break
                    }
                }, receiveValue: { value in
                    defer { TokenManager.shared.removeBox(by: id) }
                    guard proQueue.sync(execute: { return firstValue }) == nil else { return }
                    proQueue.async(flags: .barrier) { firstValue = .success(value) }

                    completion.send(value)
                    completion.send(completion: .finished)
                })
                tokens.append(token)
            }
            TokenManager.shared.addBox(.init(uuid: id, tokens: tokens))
        }
    }
}
