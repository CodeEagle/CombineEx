import Combine
import Foundation

public func any<Value, Failure>(_ promises: AnyPublisher<Value, Failure>..., on queue: DispatchQueue = .main) -> AnyPublisher<[Result<Value, Failure>], Never> where Failure: Error {
    return any(promises, on: queue)
}

public func any<Value, Failure>(_ promises: [AnyPublisher<Value, Failure>], on queue: DispatchQueue = .main) -> AnyPublisher<[Result<Value, Failure>], Never> where Failure: Error {
    return .init { (completion) in
        let group = DispatchGroup()
        var results: [Result<Value, Failure>] = []
        let proQueue: DispatchQueue = .init(label: "any.property", attributes: .concurrent)
        for promise in promises {
            promise.sink(in: group, with: { (result) in
                proQueue.async(flags: .barrier) { results.append(result) }
            })
        }
        group.notify(queue: queue) {
            _ = completion.receive(results)
            completion.receive(completion: .finished)
        }
    }
}

public func any<A, B, FA, FB>(_ a: AnyPublisher<A, FA>, _ b: AnyPublisher<B, FB>, on queue: DispatchQueue = .main) -> AnyPublisher<(Result<A, FA>, Result<B, FB>), Never> where FA: Error, FB: Error {
    
    return .init { (completion) in
        let group = DispatchGroup()
        let proQueue: DispatchQueue = .init(label: "any.property", attributes: .concurrent)
        var resultA: Result<A, FA>?
        var resultB: Result<B, FB>?
        
        a.sink(in: group, with: { (result) in
            proQueue.async(flags: .barrier) { resultA = result }
        })
        b.sink(in: group, with: { (result) in
            proQueue.async(flags: .barrier) { resultB = result }
        })
        group.notify(queue: queue) {
            guard let a = proQueue.sync (execute: { resultA }),
                let b = proQueue.sync (execute: { resultB }) else { return }
            _ = completion.receive((a, b))
            completion.receive(completion: .finished)
        }
    }
}

public func any<A, B, C, FA, FB, FC>(_ a: AnyPublisher<A, FA>, _ b: AnyPublisher<B, FB>, _ c: AnyPublisher<C, FC>, on queue: DispatchQueue = .main) -> AnyPublisher<(Result<A, FA>, Result<B, FB>, Result<C, FC>), Never> where FA: Error, FB: Error, FC: Error {
    return .init { (completion) in
        let group = DispatchGroup()
        let proQueue: DispatchQueue = .init(label: "any.property", attributes: .concurrent)
        var resultA: Result<A, FA>?
        var resultB: Result<B, FB>?
        var resultC: Result<C, FC>?
        
        a.sink(in: group, with: { (result) in
            proQueue.async(flags: .barrier) { resultA = result }
        })
        b.sink(in: group, with: { (result) in
            proQueue.async(flags: .barrier) { resultB = result }
        })
        c.sink(in: group, with: { (result) in
            proQueue.async(flags: .barrier) { resultC = result }
        })
        
        group.notify(queue: queue) {
            guard let a = proQueue.sync (execute: { resultA }),
                let b = proQueue.sync (execute: { resultB }),
                let c = proQueue.sync (execute: { resultC }) else { return }
            _ = completion.receive((a, b, c))
            completion.receive(completion: .finished)
        }
    }
}

public func any<A, B, C, D, FA, FB, FC, FD>(_ a: AnyPublisher<A, FA>, _ b: AnyPublisher<B, FB>, _ c: AnyPublisher<C, FC>, _ d: AnyPublisher<D, FD>, on queue: DispatchQueue = .main) -> AnyPublisher<(Result<A, FA>, Result<B, FB>, Result<C, FC>, Result<D, FD>), Never> where FA: Error, FB: Error, FC: Error, FD: Error {
    return .init { (completion) in
        let group = DispatchGroup()
        let proQueue: DispatchQueue = .init(label: "any.property", attributes: .concurrent)
        var resultA: Result<A, FA>?
        var resultB: Result<B, FB>?
        var resultC: Result<C, FC>?
        var resultD: Result<D, FD>?
        
        a.sink(in: group, with: { (result) in
            proQueue.async(flags: .barrier) { resultA = result }
        })
        b.sink(in: group, with: { (result) in
            proQueue.async(flags: .barrier) { resultB = result }
        })
        c.sink(in: group, with: { (result) in
            proQueue.async(flags: .barrier) { resultC = result }
        })
        d.sink(in: group, with: { (result) in
            proQueue.async(flags: .barrier) { resultD = result }
        })
        
        group.notify(queue: queue) {
            guard let a = proQueue.sync (execute: { resultA }),
                let b = proQueue.sync (execute: { resultB }),
                let c = proQueue.sync (execute: { resultC }),
                let d = proQueue.sync (execute: { resultD }) else { return }
            _ = completion.receive((a, b, c, d))
            completion.receive(completion: .finished)
        }
    }
}
