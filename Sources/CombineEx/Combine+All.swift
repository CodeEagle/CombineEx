import Combine
import Foundation

public func all<Value, Failure>(_ promises: AnyPublisher<Value, Failure>..., on queue: DispatchQueue = .main) -> AnyPublisher<[Value], Failure> where Failure: Error {
    all(promises, on: queue)
}

public func all<Value, Failure>(_ promises: [AnyPublisher<Value, Failure>], on queue: DispatchQueue = .main) -> AnyPublisher<[Value], Failure> where Failure: Error {
    
    .init { (completion) in
        let group = DispatchGroup()
        var error: Failure?
        var values: [Int : Value] = [:]
        let proQueue: DispatchQueue = .init(label: "all.property", attributes: .concurrent)
        
        for (index, item) in promises.enumerated() {
            
            guard proQueue.sync(execute: { return error }) == nil else { return }
            
            item.sink(in: group, with: { result in
                
                guard proQueue.sync (execute: { return error }) == nil else { return }
                
                switch result {
                case let .success(v):
                    proQueue.async(flags: .barrier) { values[index] = v }
                    
                case let .failure(e):
                    proQueue.async(flags: .barrier) { error = e }
                    completion.receive(completion: .failure(e))
                }
            })
        }
        
        group.notify(queue: queue) {
            guard error == nil else { return }
            
            let list =  proQueue.sync(execute: { values.sorted { $0.key < $1.key } })
            let ret = list.map { $0.value }
            
            _ = completion.receive(ret)
            completion.receive(completion: .finished)
        }
    }
}

public func all<A, B, FA, FB>(_ a: AnyPublisher<A, FA>, _ b: AnyPublisher<B, FB>, on queue: DispatchQueue = .main) -> AnyPublisher<(A, B), EitherBio<FA, FB>> where FA: Error, FB: Error {
    
    return .init { (completion) in
        let group = DispatchGroup()
        var error: EitherBio<FA, FB>?
        let proQueue: DispatchQueue = .init(label: "all.property", attributes: .concurrent)
        var resultA: A?
        var resultB: B?
        
        a.sink(in: group, with: { result in
            
            guard proQueue.sync (execute: { error }) == nil else { return }
            
            switch result {
            case let .success(v):
                proQueue.async(flags: .barrier) { resultA = v }
                
            case let .failure(e):
                proQueue.async(flags: .barrier) { error = .a(e) }
                completion.receive(completion: .failure(.a(e)))
            }
        })
        
        b.sink(in: group, with: { result in
            
            guard proQueue.sync (execute: { return error }) == nil else { return }
            
            switch result {
            case let .success(v):
                proQueue.async(flags: .barrier) { resultB = v }
                
            case let .failure(e):
                proQueue.async(flags: .barrier) { error = .b(e) }
                completion.receive(completion: .failure(.b(e)))
            }
        })
        
        group.notify(queue: queue) {
            guard error == nil,
                let a = proQueue.sync (execute: { resultA }),
                let b = proQueue.sync (execute: { resultB }) else { return }
            let ret = (a, b)
            
            _ = completion.receive(ret)
            completion.receive(completion: .finished)
        }
    }
}

public func all<A, B, C, FA, FB, FC>(_ a: AnyPublisher<A, FA>, _ b: AnyPublisher<B, FB>, _ c: AnyPublisher<C, FC>, on queue: DispatchQueue = .main) -> AnyPublisher<(A, B, C), EitherTri<FA, FB, FC>> where FA: Error, FB: Error, FC: Error {
    return .init { (completion) in
        let group = DispatchGroup()
        var error: EitherTri<FA, FB, FC>?
        let proQueue: DispatchQueue = .init(label: "all.property", attributes: .concurrent)
        var resultA: A?
        var resultB: B?
        var resultC: C?
        
        a.sink(in: group, with: { result in
            
            guard proQueue.sync (execute: { return error }) == nil else { return }
            
            switch result {
            case let .success(v):
                proQueue.async(flags: .barrier) { resultA = v }
                
            case let .failure(e):
                proQueue.async(flags: .barrier) { error = .a(e) }
                completion.receive(completion: .failure(.a(e)))
            }
        })
        
        b.sink(in: group, with: { result in
            
            guard proQueue.sync (execute: { return error }) == nil else { return }
            
            switch result {
            case let .success(v):
                proQueue.async(flags: .barrier) { resultB = v }
                
            case let .failure(e):
                proQueue.async(flags: .barrier) { error = .b(e) }
                completion.receive(completion: .failure(.b(e)))
            }
        })
        
        c.sink(in: group, with: { result in
            
            guard proQueue.sync (execute: { return error }) == nil else { return }
            
            switch result {
            case let .success(v):
                proQueue.async(flags: .barrier) { resultC = v }
                
            case let .failure(e):
                proQueue.async(flags: .barrier) { error = .c(e) }
                completion.receive(completion: .failure(.c(e)))
            }
        })
        
        group.notify(queue: queue) {
            guard error == nil,
                let a = proQueue.sync (execute: { resultA }),
                let b = proQueue.sync (execute: { resultB }),
                let c = proQueue.sync (execute: { resultC }) else { return }
            let ret = (a, b, c)
            
            _ = completion.receive(ret)
            completion.receive(completion: .finished)
        }
    }
}

public func all<A, B, C, D, FA, FB, FC, FD>(_ a: AnyPublisher<A, FA>, _ b: AnyPublisher<B, FB>, _ c: AnyPublisher<C, FC>, _ d: AnyPublisher<D, FD>, on queue: DispatchQueue = .main) -> AnyPublisher<(A, B, C, D), EitherFor<FA, FB, FC, FD>> where FA: Error, FB: Error, FC: Error, FD: Error {
    return .init { (completion) in
        let group = DispatchGroup()
        var error: EitherFor<FA, FB, FC, FD>?
        let proQueue: DispatchQueue = .init(label: "all.property", attributes: .concurrent)
        var resultA: A?
        var resultB: B?
        var resultC: C?
        var resultD: D?
        
        a.sink(in: group, with: { result in
            
            guard proQueue.sync (execute: { return error }) == nil else { return }
            
            switch result {
            case let .success(v):
                proQueue.async(flags: .barrier) { resultA = v }
                
            case let .failure(e):
                proQueue.async(flags: .barrier) { error = .a(e) }
                completion.receive(completion: .failure(.a(e)))
            }
        })
        
        b.sink(in: group, with: { result in
            
            guard proQueue.sync (execute: { return error }) == nil else { return }
            
            switch result {
            case let .success(v):
                proQueue.async(flags: .barrier) { resultB = v }
                
            case let .failure(e):
                proQueue.async(flags: .barrier) { error = .b(e) }
                completion.receive(completion: .failure(.b(e)))
            }
        })
        
        c.sink(in: group, with: { result in
            
            guard proQueue.sync (execute: { return error }) == nil else { return }
            
            switch result {
            case let .success(v):
                proQueue.async(flags: .barrier) { resultC = v }
                
            case let .failure(e):
                proQueue.async(flags: .barrier) { error = .c(e) }
                completion.receive(completion: .failure(.c(e)))
            }
        })
        
        d.sink(in: group, with: { result in
            
            guard proQueue.sync (execute: { return error }) == nil else { return }
            
            switch result {
            case let .success(v):
                proQueue.async(flags: .barrier) { resultD = v }
                
            case let .failure(e):
                proQueue.async(flags: .barrier) { error = .d(e) }
                completion.receive(completion: .failure(.d(e)))
            }
        })
        
        group.notify(queue: queue) {
            guard error == nil,
                let a = proQueue.sync (execute: { resultA }),
                let b = proQueue.sync (execute: { resultB }),
                let c = proQueue.sync (execute: { resultC }),
                let d = proQueue.sync (execute: { resultD }) else { return }
            let ret = (a, b, c, d)
            
            _ = completion.receive(ret)
            completion.receive(completion: .finished)
        }
    }
}
