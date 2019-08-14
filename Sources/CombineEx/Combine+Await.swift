import Combine
import Foundation

extension Publisher {
    public func await() throws -> Output {
        let semaphore = DispatchSemaphore(value: 0)
        var result: Result<Output, Failure>?
        let proQueue: DispatchQueue = .init(label: "all.property", attributes: .concurrent)

        let token = sink(receiveCompletion: { info in
            switch info {
            case let .failure(e): proQueue.async(flags: .barrier) { result = .failure(e) }
            case .finished: break
            }
            semaphore.signal()
        }, receiveValue: { (value) in
            proQueue.async(flags: .barrier) { result = .success(value) }
        })
        let id = UUID()
        TokenManager.shared.addBox(.init(uuid: id, tokens: [token]))
        defer { TokenManager.shared.removeBox(by: id) }
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
