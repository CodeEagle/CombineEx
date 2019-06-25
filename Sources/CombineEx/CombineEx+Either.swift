import Foundation

public enum EitherBio<A: Error, B: Error>: Error {
    case a(A)
    case b(B)
}

public enum EitherTri<A: Error, B: Error, C: Error>: Error {
    case a(A)
    case b(B)
    case c(C)
}

public enum EitherFor<A: Error, B: Error, C: Error, D: Error>: Error {
    case a(A)
    case b(B)
    case c(C)
    case d(D)
}

public enum AwaitError: Error {
    case unknown
}
