import Combine
import Foundation

public func any<Value, Failure>(_ promises: AnyPublisher<Value, Failure>..., on queue: DispatchQueue = .main) -> AnyPublisher<[Result<Value, Failure>], Never> where Failure: Error {
    return any(promises, on: queue)
}

public func any<Value, Failure>(_ promises: [AnyPublisher<Value, Failure>], on queue: DispatchQueue = .main) -> AnyPublisher<[Result<Value, Failure>], Never> where Failure: Error {
    return .passThrough { (completion) in
        let group = DispatchGroup()
        var results: [Result<Value, Failure>] = []
        let proQueue: DispatchQueue = .init(label: "any.property", attributes: .concurrent)
        var tokens: [AnyCancellable] = []

        for promise in promises {
            let token = promise.sink(in: group, with: { (result) in
                proQueue.async(flags: .barrier) { results.append(result) }
            })
            tokens.append(token)
        }
        let id: UUID = .init()
        TokenManager.shared.addBox(.init(uuid: id, tokens: tokens))
        group.notify(queue: queue) {
            defer { TokenManager.shared.removeBox(by: id) }
            completion.send(results)
            completion.send(completion: .finished)
        }
    }
}

public func any<A, B, FA, FB>(_ a: AnyPublisher<A, FA>, _ b: AnyPublisher<B, FB>, on queue: DispatchQueue = .main) -> AnyPublisher<(Result<A, FA>, Result<B, FB>), Never> where FA: Error, FB: Error {
    
    return .passThrough { (completion) in
        let group = DispatchGroup()
        let proQueue: DispatchQueue = .init(label: "any.property", attributes: .concurrent)
        var resultA: Result<A, FA>?
        var resultB: Result<B, FB>?
        
        let tokenA = a.sink(in: group, with: { (result) in
            proQueue.async(flags: .barrier) { resultA = result }
        })
        let tokenB = b.sink(in: group, with: { (result) in
            proQueue.async(flags: .barrier) { resultB = result }
        })
        let id: UUID = .init()
        let tokens: [AnyCancellable] = [tokenA, tokenB]
        TokenManager.shared.addBox(.init(uuid: id, tokens: tokens))
        group.notify(queue: queue) {
            defer { TokenManager.shared.removeBox(by: id) }
            guard let a = proQueue.sync (execute: { resultA }),
                let b = proQueue.sync (execute: { resultB }) else { return }
            completion.send((a, b))
            completion.send(completion: .finished)
        }
    }
}

public func any<A, B, C, FA, FB, FC>(_ a: AnyPublisher<A, FA>, _ b: AnyPublisher<B, FB>, _ c: AnyPublisher<C, FC>, on queue: DispatchQueue = .main) -> AnyPublisher<(Result<A, FA>, Result<B, FB>, Result<C, FC>), Never> where FA: Error, FB: Error, FC: Error {
    return .passThrough { (completion) in
        let group = DispatchGroup()
        let proQueue: DispatchQueue = .init(label: "any.property", attributes: .concurrent)
        var resultA: Result<A, FA>?
        var resultB: Result<B, FB>?
        var resultC: Result<C, FC>?

        let tokenA = a.sink(in: group, with: { (result) in
            proQueue.async(flags: .barrier) { resultA = result }
        })
        let tokenB = b.sink(in: group, with: { (result) in
            proQueue.async(flags: .barrier) { resultB = result }
        })
        let tokenC = c.sink(in: group, with: { (result) in
            proQueue.async(flags: .barrier) { resultC = result }
        })

        let id: UUID = .init()
        let tokens: [AnyCancellable] = [tokenA, tokenB, tokenC]
        TokenManager.shared.addBox(.init(uuid: id, tokens: tokens))
        group.notify(queue: queue) {
            defer { TokenManager.shared.removeBox(by: id) }
            guard let a = proQueue.sync (execute: { resultA }),
                let b = proQueue.sync (execute: { resultB }),
                let c = proQueue.sync (execute: { resultC }) else { return }
            completion.send((a, b, c))
            completion.send(completion: .finished)
        }
    }
}

public func any<A, B, C, D, FA, FB, FC, FD>(_ a: AnyPublisher<A, FA>, _ b: AnyPublisher<B, FB>, _ c: AnyPublisher<C, FC>, _ d: AnyPublisher<D, FD>, on queue: DispatchQueue = .main) -> AnyPublisher<(Result<A, FA>, Result<B, FB>, Result<C, FC>, Result<D, FD>), Never> where FA: Error, FB: Error, FC: Error, FD: Error {
    return .passThrough { (completion) in
        let group = DispatchGroup()
        let proQueue: DispatchQueue = .init(label: "any.property", attributes: .concurrent)
        var resultA: Result<A, FA>?
        var resultB: Result<B, FB>?
        var resultC: Result<C, FC>?
        var resultD: Result<D, FD>?
        
        let tokenA = a.sink(in: group, with: { (result) in
            proQueue.async(flags: .barrier) { resultA = result }
        })
        let tokenB = b.sink(in: group, with: { (result) in
            proQueue.async(flags: .barrier) { resultB = result }
        })
        let tokenC = c.sink(in: group, with: { (result) in
            proQueue.async(flags: .barrier) { resultC = result }
        })
        let tokenD = d.sink(in: group, with: { (result) in
            proQueue.async(flags: .barrier) { resultD = result }
        })

        let id: UUID = .init()
        let tokens: [AnyCancellable] = [tokenA, tokenB, tokenC, tokenD]
        TokenManager.shared.addBox(.init(uuid: id, tokens: tokens))
        group.notify(queue: queue) {
            defer { TokenManager.shared.removeBox(by: id) }
            guard let a = proQueue.sync (execute: { resultA }),
                let b = proQueue.sync (execute: { resultB }),
                let c = proQueue.sync (execute: { resultC }),
                let d = proQueue.sync (execute: { resultD }) else { return }
            completion.send((a, b, c, d))
            completion.send(completion: .finished)
        }
    }
}
