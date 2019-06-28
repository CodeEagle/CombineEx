import Combine

public extension Subscriber {
    func subscribe<P>(to publisher: P) where P : Publisher, Self.Failure == P.Failure, P.Output == Self.Input {
        publisher.addSubscriber(self)
    }
}
