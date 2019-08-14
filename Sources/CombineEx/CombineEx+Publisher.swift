import Combine
import Dispatch
// MARK: - Public
public extension Publisher {
    /// Attaches the specified subscriber to this publisher.
    ///
    /// Always call this function instead of `receive(subscriber:)`.
    /// Adopters of `Publisher` must implement `receive(subscriber:)`. The implementation of `subscribe(_:)` in this extension calls through to `receive(subscriber:)`.
    /// - SeeAlso: `receive(subscriber:)`
    /// - Parameters:
    ///     - subscriber: The subscriber to attach to this `Publisher`. After attaching, the subscriber can start to receive values.
    @inline(__always)
    func addSubscriber<S>(_ subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
        subscribe(subscriber)
    }
}

// MARK: - Internal
extension Publisher {
    func sink(in group: DispatchGroup, with completion: @escaping (Result<Output, Failure>) -> Void) -> AnyCancellable {
        group.enter()
        return sink(receiveCompletion: { info in
            switch info {
            case let .failure(error):
                completion(.failure(error))
            case .finished: break
            }
            group.leave()
        }, receiveValue: { (v) in
            completion(.success(v))
        })
    }
}

extension AnyPublisher {
    public static func passThrough(_ processe: (PassthroughSubject<Output, Failure>) -> Void) -> AnyPublisher<Output, Failure> {
        let subject: PassthroughSubject<Output, Failure> = .init()
        processe(subject)
        return subject.eraseToAnyPublisher()
    }
}
