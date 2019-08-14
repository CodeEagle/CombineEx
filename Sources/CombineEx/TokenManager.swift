import Combine
import Foundation

struct AnyCancelableBox {
    let uuid: UUID
    let tokens: [AnyCancellable]
    init(uuid: UUID, tokens: [AnyCancellable]) {
        self.uuid = uuid
        self.tokens = tokens
    }
}

final class TokenManager {
    static let shared = TokenManager()
    private let _queue: DispatchQueue = .init(label: "TokenManager.property", attributes: .concurrent)
    private lazy var _tokenMap: [UUID : AnyCancelableBox] = [:]
    private var tokenMap: [UUID : AnyCancelableBox] {
        get { return _queue.sync { _tokenMap } }
        set { _queue.async(flags: .barrier) { self._tokenMap = newValue } }
    }

    func addBox(_ value: AnyCancelableBox) {
        tokenMap[value.uuid] = value
    }

    func removeBox(by id: UUID) {
        tokenMap[id] = nil
    }
}
