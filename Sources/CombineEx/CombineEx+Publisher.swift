import Combine
import Dispatch
// MARK: - Public
extension Publisher {
    /// **DiscardableResult** Attaches a subscriber with closure-based behavior.
    ///
    /// This method creates the subscriber and immediately requests an unlimited number of values, prior to returning the subscriber.
    /// - parameter onValue: The closure to execute on receipt of a value. If `nil`, the sink uses an empty closure.
    /// - parameter onCompletion: The closure to execute on completion. If `nil`, the sink uses an empty closure.
    /// - Returns: A subscriber that performs the provided closures upon receiving values or completion.
    @discardableResult public func discardableSink(onValue: @escaping ((Self.Output) -> Void), onCompletion: ((Subscribers.Completion<Self.Failure>) -> Void)? = nil) -> Subscribers.Sink<Self> {
        return sink(receiveCompletion: onCompletion, receiveValue: onValue)
    }
}

// MARK: - Internal
extension Publisher {
    func sink(in group: DispatchGroup, with completion: @escaping (Result<Output, Failure>) -> Void) {
        group.enter()
        discardableSink(onValue: { (v) in
            completion(.success(v))
        }, onCompletion: { info in
            switch info {
            case let .failure(error): completion(.failure(error))
            case .finished: break
            }
            group.leave()
        })
    }
}
