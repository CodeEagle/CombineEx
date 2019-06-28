import Combine

public extension Subscriber {
    @inline(__always)
    func subscribe<P>(to publisher: P) where P : Publisher, Self.Failure == P.Failure, P.Output == Self.Input {
        publisher.addSubscriber(self)
    }
}
