import Combine
import Foundation

public func all<Value, Failure>(_ promises: AnyPublisher<Value, Failure>..., on queue: DispatchQueue = .main, maxConcurrent: Int = 10) -> AnyPublisher<[Value], Failure> where Failure: Error {
    all(promises, on: queue, maxConcurrent: maxConcurrent)
}

public func all<Value, Failure>(_ promises: [AnyPublisher<Value, Failure>], on queue: DispatchQueue = .main, maxConcurrent: Int = 10) -> AnyPublisher<[Value], Failure> where Failure: Error {
    .passThrough { (subject) in
        let group = DispatchGroup()
        var error: Failure?
        var tokens: [AnyCancellable] = []
        var values: [Int : Value] = [:]
        let proQueue: DispatchQueue = .init(label: "all.property", attributes: .concurrent)
        let size = promises.count
        
        func ended() {
            guard error == nil else { return }

            let list = proQueue.sync(execute: { values.sorted { $0.key < $1.key } })
            let ret = list.map { $0.value }

            subject.send(ret)
            subject.send(completion: .finished)
        }
        if maxConcurrent < size, maxConcurrent > 0 {
            var _currentEnqueuedCount = 0
            var _enqueuedIndex = 0
            var _completedCount = 0
            var currentEnqueuedCount: Int {
                get { proQueue.sync { _currentEnqueuedCount } }
                set { proQueue.async(flags: .barrier) {
                    _currentEnqueuedCount = newValue
                }}
            }
            var enqueuedIndex: Int {
                get { proQueue.sync { _enqueuedIndex } }
                set { proQueue.async(flags: .barrier) {
                    _enqueuedIndex = newValue
                }}
            }
            var completedCount: Int {
                get { proQueue.sync { _completedCount } }
                set { proQueue.async(flags: .barrier) {
                    _completedCount = newValue
                }}
            }
            
            func startOne() {
                let item = promises[enqueuedIndex]
                enqueuedIndex += 1
                currentEnqueuedCount += 1
                guard proQueue.sync(execute: { return error }) == nil else { return }
                let token = item.sink( { [index = enqueuedIndex] result in
                    defer {
                        currentEnqueuedCount -= 1
                        completedCount += 1
                        checkAndStartNext()
                    }
                    guard proQueue.sync (execute: { return error }) == nil else { return }
                    switch result {
                    case let .success(v):
                        proQueue.async(flags: .barrier) { values[index] = v }

                    case let .failure(e):
                        proQueue.async(flags: .barrier) { error = e }
                        subject.send(completion: .failure(e))
                    }
                })
                tokens.append(token)
            }
            
            func checkAndStartNext() {
                while currentEnqueuedCount < maxConcurrent, enqueuedIndex < size {
                    startOne()
                }
                
                if completedCount == size {
                    ended()
                }
            }
            checkAndStartNext()
        } else {
            for (index, item) in promises.enumerated() {

                guard proQueue.sync(execute: { return error }) == nil else { return }

                let token = item.sink(in: group, with: { result in
                    guard proQueue.sync (execute: { return error }) == nil else { return }

                    switch result {
                    case let .success(v):
                        proQueue.async(flags: .barrier) {
                            values[index] = v
                        }

                    case let .failure(e):
                        proQueue.async(flags: .barrier) { error = e }
                        subject.send(completion: .failure(e))
                    }
                })
                tokens.append(token)
            }
            
            let id: UUID = .init()
            TokenManager.shared.addBox(.init(uuid: id, tokens: tokens))

            group.notify(queue: queue) {
                defer { TokenManager.shared.removeBox(by: id) }
                ended()
            }
        }
    }
}

public func all<A, B, FA, FB>(_ a: AnyPublisher<A, FA>, _ b: AnyPublisher<B, FB>, on queue: DispatchQueue = .main) -> AnyPublisher<(A, B), EitherBio<FA, FB>> where FA: Error, FB: Error {
    .passThrough { (completion) in
        let group = DispatchGroup()
        var error: EitherBio<FA, FB>?
        let proQueue: DispatchQueue = .init(label: "all.property", attributes: .concurrent)
        var resultA: A?
        var resultB: B?

        let tokenA = a.sink(in: group, with: { result in
            guard proQueue.sync (execute: { error }) == nil else { return }
            
            switch result {
            case let .success(v):
                proQueue.async(flags: .barrier) { resultA = v }
                
            case let .failure(e):
                proQueue.async(flags: .barrier) { error = .a(e) }
                completion.send(completion: .failure(.a(e)))
            }
        })
        
        let tokenB = b.sink(in: group, with: { result in
            
            guard proQueue.sync (execute: { return error }) == nil else { return }
            
            switch result {
            case let .success(v):
                proQueue.async(flags: .barrier) { resultB = v }
                
            case let .failure(e):
                proQueue.async(flags: .barrier) { error = .b(e) }
                completion.send(completion: .failure(.b(e)))
            }
        })

        let id: UUID = .init()
        let tokens: [AnyCancellable] = [tokenA, tokenB]
        TokenManager.shared.addBox(.init(uuid: id, tokens: tokens))
        group.notify(queue: queue) {
            defer { TokenManager.shared.removeBox(by: id) }
            guard error == nil,
                let a = proQueue.sync (execute: { resultA }),
                let b = proQueue.sync (execute: { resultB }) else { return }
            let ret = (a, b)
            
            completion.send(ret)
            completion.send(completion: .finished)
        }
    }
}

public func all<A, B, C, FA, FB, FC>(_ a: AnyPublisher<A, FA>, _ b: AnyPublisher<B, FB>, _ c: AnyPublisher<C, FC>, on queue: DispatchQueue = .main) -> AnyPublisher<(A, B, C), EitherTri<FA, FB, FC>> where FA: Error, FB: Error, FC: Error {
    .passThrough { (completion) in
        let group = DispatchGroup()
        var error: EitherTri<FA, FB, FC>?
        let proQueue: DispatchQueue = .init(label: "all.property", attributes: .concurrent)
        var resultA: A?
        var resultB: B?
        var resultC: C?

        let tokenA = a.sink(in: group, with: { result in
            
            guard proQueue.sync (execute: { return error }) == nil else { return }
            
            switch result {
            case let .success(v):
                proQueue.async(flags: .barrier) { resultA = v }
                
            case let .failure(e):
                proQueue.async(flags: .barrier) { error = .a(e) }
                completion.send(completion: .failure(.a(e)))
            }
        })
        
        let tokenB = b.sink(in: group, with: { result in
            
            guard proQueue.sync (execute: { return error }) == nil else { return }
            
            switch result {
            case let .success(v):
                proQueue.async(flags: .barrier) { resultB = v }
                
            case let .failure(e):
                proQueue.async(flags: .barrier) { error = .b(e) }
                completion.send(completion: .failure(.b(e)))
            }
        })
        
        let tokenC = c.sink(in: group, with: { result in
            
            guard proQueue.sync (execute: { return error }) == nil else { return }
            
            switch result {
            case let .success(v):
                proQueue.async(flags: .barrier) { resultC = v }
                
            case let .failure(e):
                proQueue.async(flags: .barrier) { error = .c(e) }
                completion.send(completion: .failure(.c(e)))
            }
        })

        let id: UUID = .init()
        let tokens: [AnyCancellable] = [tokenA, tokenB, tokenC]
        TokenManager.shared.addBox(.init(uuid: id, tokens: tokens))

        group.notify(queue: queue) {
            defer { TokenManager.shared.removeBox(by: id) }
            guard error == nil,
                let a = proQueue.sync (execute: { resultA }),
                let b = proQueue.sync (execute: { resultB }),
                let c = proQueue.sync (execute: { resultC }) else { return }
            let ret = (a, b, c)
            
            completion.send(ret)
            completion.send(completion: .finished)
        }
    }
}

public func all<A, B, C, D, FA, FB, FC, FD>(_ a: AnyPublisher<A, FA>, _ b: AnyPublisher<B, FB>, _ c: AnyPublisher<C, FC>, _ d: AnyPublisher<D, FD>, on queue: DispatchQueue = .main) -> AnyPublisher<(A, B, C, D), EitherFor<FA, FB, FC, FD>> where FA: Error, FB: Error, FC: Error, FD: Error {
    .passThrough { (completion) in
        let group = DispatchGroup()
        var error: EitherFor<FA, FB, FC, FD>?
        let proQueue: DispatchQueue = .init(label: "all.property", attributes: .concurrent)
        var resultA: A?
        var resultB: B?
        var resultC: C?
        var resultD: D?

        let tokenA = a.sink(in: group, with: { result in
            
            guard proQueue.sync (execute: { return error }) == nil else { return }
            
            switch result {
            case let .success(v):
                proQueue.async(flags: .barrier) { resultA = v }
                
            case let .failure(e):
                proQueue.async(flags: .barrier) { error = .a(e) }
                completion.send(completion: .failure(.a(e)))
            }
        })
        
        let tokenB = b.sink(in: group, with: { result in
            
            guard proQueue.sync (execute: { return error }) == nil else { return }
            
            switch result {
            case let .success(v):
                proQueue.async(flags: .barrier) { resultB = v }
                
            case let .failure(e):
                proQueue.async(flags: .barrier) { error = .b(e) }
                completion.send(completion: .failure(.b(e)))
            }
        })
        
        let tokenC = c.sink(in: group, with: { result in
            
            guard proQueue.sync (execute: { return error }) == nil else { return }
            
            switch result {
            case let .success(v):
                proQueue.async(flags: .barrier) { resultC = v }
                
            case let .failure(e):
                proQueue.async(flags: .barrier) { error = .c(e) }
                completion.send(completion: .failure(.c(e)))
            }
        })
        
        let tokenD = d.sink(in: group, with: { result in
            
            guard proQueue.sync (execute: { return error }) == nil else { return }
            
            switch result {
            case let .success(v):
                proQueue.async(flags: .barrier) { resultD = v }
                
            case let .failure(e):
                proQueue.async(flags: .barrier) { error = .d(e) }
                completion.send(completion: .failure(.d(e)))
            }
        })
        let id: UUID = .init()
        let tokens: [AnyCancellable] = [tokenA, tokenB, tokenC, tokenD]
        TokenManager.shared.addBox(.init(uuid: id, tokens: tokens))

        group.notify(queue: queue) {
            defer { TokenManager.shared.removeBox(by: id) }
            guard error == nil,
                let a = proQueue.sync (execute: { resultA }),
                let b = proQueue.sync (execute: { resultB }),
                let c = proQueue.sync (execute: { resultC }),
                let d = proQueue.sync (execute: { resultD }) else { return }
            let ret = (a, b, c, d)
            
            completion.send(ret)
            completion.send(completion: .finished)
        }
    }
}

