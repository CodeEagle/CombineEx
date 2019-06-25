import XCTest
import Combine
@testable import CombineEx

private let pic1 = "https://www.apple.com/autopush/cn/itunes/charts/free-apps/images/2018/2/21d871d12d8e55991510b8b7c3b069fec3fbc9027735a66af7be787290429ac4_2x.jpg"
private let pic2 = "https://www.apple.com/autopush/cn/itunes/charts/free-apps/images/2018/2/7d30a62c2b7d9e2a4736c3845ab55ab0fe386ff946b84321010a0b3dfd7cc89c_2x.jpg"
private let pic3 = "https://www.apple.com/autopush/cn/itunes/charts/free-apps/images/2018/2/71d601e027773a734e58e1c0034b022d3eac05ee0a80e367dc2edd9bb07e33a7_2x.jpg"
private let picErr = "https://hahah.com/pic.net.exist"
private let intUrl = "http://httpbin.org/anything?result=123"

final class CombineExTests: XCTestCase {
    static var allTests = [
        ("testAnyList", testAnyList),
        ("testAnyAB", testAnyAB),
        ("testAnyABC", testAnyABC),
        ("testAnyABCD", testAnyABCD),
        ("testAllList", testAllList),
        ("testAllListError", testAllListError),
        ("testAllAB", testAllAB),
        ("testAllABC", testAllABC),
        ("testAllABCD", testAllABCD),
        ("testRaceList", testRaceList),
        ("testRaceListError", testRaceListError),
        ("testAwait", testAwait),
    ]
}
// MARK: - Any Tests
extension CombineExTests {
    enum TestError: Swift.Error {
        case noData
    }
    
    func testAnyList() {
        let pics = [pic1, pic2, picErr]
        asyncTest { (e) in
            let promises = pics.map { (url) -> AnyPublisher<Data, TestError> in
                return .init { (completion) in
                    DispatchQueue.global().async {
                        if let d = NSData(contentsOf: URL(string: url)!) {
                            _ = completion.receive(d as Data)
                            completion.receive(completion: .finished)
                        } else {
                            completion.receive(completion: .failure(TestError.noData))
                        }
                    }
                }
            }
            let expectSuccessCount = 2
            let expectFailureCount = 1
            any(promises).discardableSink(onValue: { (result) in
                var successCount = 0
                var failureCount = 0
                for item in result {
                    switch item {
                    case let .failure(e):
                        failureCount += 1
                        assert(e == TestError.noData)
                        
                    case .success:
                        successCount += 1
                    }
                }
                assert(successCount == expectSuccessCount, "must have two item success")
                assert(failureCount == expectFailureCount, "must have one item failure")
            }, onCompletion: { _ in
                e.fulfill()
            })
        }
    }
    
    func testAnyAB() {
        let a = dataPublisher(for: pic1)
        let b = stringPublisher(for: picErr)
        asyncTest { (e) in
            any(a, b).discardableSink(onValue: { (value) in
                let aValue = try? value.0.get()
                let bValue = try? value.1.get()
                assert(aValue != nil, "A must not fail")
                assert(bValue == nil, "B must fail")
            }, onCompletion: { _ in
                e.fulfill()
            })
        }
    }
    
    func testAnyABC() {
        let a = dataPublisher(for: pic1)
        let b = stringPublisher(for: picErr)
        let c = intPublisher(for: intUrl)
        asyncTest { (e) in
            any(a, b, c).discardableSink(onValue: { (value) in
                let aValue = try? value.0.get()
                let bValue = try? value.1.get()
                let cValue = try? value.2.get()
                assert(aValue != nil, "A must not fail")
                assert(bValue == nil, "B must fail")
                assert(cValue != nil, "C must not fail")
            }, onCompletion: { _ in
                e.fulfill()
            })
        }
    }
    
    func testAnyABCD() {
        let a = dataPublisher(for: pic1)
        let b = stringPublisher(for: picErr)
        let c = intPublisher(for: intUrl)
        let d = dataPublisher(for: pic2)
        asyncTest { (e) in
            any(a, b, c, d).discardableSink(onValue: { (value) in
                let aValue = try? value.0.get()
                let bValue = try? value.1.get()
                let cValue = try? value.2.get()
                let dValue = try? value.3.get()
                assert(aValue != nil, "A must not fail")
                assert(bValue == nil, "B must fail")
                assert(cValue != nil, "C must not fail")
                assert(dValue != nil, "D must not fail")
            }, onCompletion: { _ in
                e.fulfill()
            })
        }
    }
}

// MARK: - All Test
extension CombineExTests {
    enum AllError: Error {
        case somethingWentWrong
    }
    func testAllList() {
        let a = AnyPublisher<String, Never>.init { (completion) in
            _ = completion.receive("A")
            completion.receive(completion: .finished)
        }
        let p = AnyPublisher<String, Never>.init { (completion) in
            _ = completion.receive("P")
            completion.receive(completion: .finished)
        }
        let p2 = AnyPublisher<String, Never>.init { (completion) in
            _ = completion.receive("P")
            completion.receive(completion: .finished)
        }
        let l = AnyPublisher<String, Never>.init { (completion) in
            _ = completion.receive("L")
            completion.receive(completion: .finished)
        }
        let e = AnyPublisher<String, Never>.init { (completion) in
            _ = completion.receive("E")
            completion.receive(completion: .finished)
        }
        asyncTest { (rr) in
            _ = all(a, p, p2, l, e).sink(receiveCompletion: { _ in
                rr.fulfill()
            }, receiveValue: { list in
                let result = list.joined()
                print(result)
                assert(result == "APPLE")
            })
        }
    }
    
    func testAllListError() {
        let a = AnyPublisher<String, AllError>.init { (completion) in
            _ = completion.receive("A")
            completion.receive(completion: .finished)
        }
        let p = AnyPublisher<String, AllError>.init { (completion) in
            _ = completion.receive("P")
            completion.receive(completion: .finished)
        }
        let p2 = AnyPublisher<String, AllError>.init { (completion) in
            completion.receive(completion: .failure(.somethingWentWrong))
        }
        let l = AnyPublisher<String, AllError>.init { (completion) in
            _ = completion.receive("L")
            completion.receive(completion: .finished)
        }
        let e = AnyPublisher<String, AllError>.init { (completion) in
            _ = completion.receive("E")
            completion.receive(completion: .finished)
        }
        
        asyncTest { (rr) in
            _ = all(a, p, p2, l, e).sink(receiveCompletion: { info in
                switch info {
                case let .failure(err):
                    print(err)
                    rr.fulfill()
                    
                case .finished:
                    notExpectReachThisLine()
                }
                
            }, receiveValue: { list in
                notExpectReachThisLine()
            })
        }
    }
    
    func testAllAB() {
        let a = dataPublisher(for: pic1)
        let b = stringPublisher(for: picErr)
        asyncTest { (e) in
            all(a, b).discardableSink(onValue: { (value) in
                notExpectReachThisLine()
            }, onCompletion: { info in
                switch info {
                case let .failure(error):
                    switch error {
                    case .a: notExpectReachThisLine()
                    case let .b(errB):
                        print(errB)
                        e.fulfill()
                    }
                case .finished:
                    notExpectReachThisLine()
                }
            })
        }
    }
    
    func testAllABC() {
        let a = dataPublisher(for: pic1)
        let b = dataPublisher(for: pic2)
        let c = intPublisher(for: intUrl)
        asyncTest { (e) in
            all(a, b, c).discardableSink(onValue: { (value) in
                e.fulfill()
            })
        }
    }
    
    func testAllABCD() {
        let a = dataPublisher(for: pic1)
        let b = stringPublisher(for: pic2)
        let c = intPublisher(for: intUrl)
        let d = dataPublisher(for: pic3)
        asyncTest { (e) in
            all(a, b, c, d).discardableSink(onValue: { (value) in
                e.fulfill()
            })
        }
    }
}

// MARK: - Race Test
extension CombineExTests {
    enum RaceError: Error {
        case oops
    }
    
    func testRaceList() {
        let itemA = AnyPublisher<String, AllError>.init { (completion) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                _ = completion.receive("Lincoln")
                completion.receive(completion: .finished)
            }
        }
        
        let itemB = AnyPublisher<String, AllError>.init { (completion) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                _ = completion.receive("Alice")
                completion.receive(completion: .finished)
            }
        }
        
        asyncTest { (e) in
            _ = race(itemA, itemB).sink(receiveCompletion: { _ in
                e.fulfill()
            }, receiveValue: { result in
                assert(result == "Lincoln")
            })
        }
    }
    
    func testRaceListError() {
        let itemA = AnyPublisher<String, RaceError>.init { (completion) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                completion.receive(completion: .failure(.oops))
            }
        }
        
        let itemB = AnyPublisher<String, RaceError>.init { (completion) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                completion.receive(completion: .failure(.oops))
            }
        }
        
        asyncTest { (e) in
            _ = race(itemA, itemB).sink(receiveCompletion: { info in
                switch info {
                case .failure: e.fulfill()
                case .finished: break
                }
            }, receiveValue: { result in
                notExpectReachThisLine()
            })
        }
    }
}
// MARK: - Await
extension CombineExTests {
    func testAwait() {
        let c = intPublisher(for: intUrl)
        let result = try! c.await()
        print(result)
        assert(result == 123)
    }
}
// MARK: - Utils

func notExpectReachThisLine() -> Never {
    fatalError("This line of code should never be reached")
}

extension CombineExTests {
    
    func asyncTest(timeout: TimeInterval = 30, block: (XCTestExpectation) -> ()) {
        let expectation: XCTestExpectation = self.expectation(description: "❌:Timeout")
        block(expectation)
        self.waitForExpectations(timeout: timeout) { (error) in
            if let err = error {
                XCTFail("time out: \(err)")
            } else {
                XCTAssert(true, "success")
            }
        }
    }
    
    private func dataPublisher(for url: String) -> AnyPublisher<Data, TestError> {
        return .init { (completion) in
            DispatchQueue.global(qos: .background).async {
                if let d = NSData(contentsOf: URL(string: url)!) {
                    _ = completion.receive(d as Data)
                    completion.receive(completion: .finished)
                } else {
                    completion.receive(completion: .failure(TestError.noData))
                }
            }
        }
    }
    
    private func stringPublisher(for url: String) -> AnyPublisher<String, TestError> {
        return .init { (completion) in
            DispatchQueue.global(qos: .utility).async {
                if let d = NSData(contentsOf: URL(string: url)!) {
                    _ = completion.receive(d.description)
                    completion.receive(completion: .finished)
                } else {
                    completion.receive(completion: .failure(TestError.noData))
                }
            }
        }
    }
    
    private func intPublisher(for url: String) -> AnyPublisher<Int, TestError> {
        return .init { (completion) in
            DispatchQueue.global(qos: .userInitiated).async {
                if let d = NSData(contentsOf: URL(string: url)!) {
                    let result = try! JSONDecoder().decode(Warp.self, from: d as Data)
                    _ = completion.receive(Int(result.args.result)!)
                    completion.receive(completion: .finished)
                } else {
                    completion.receive(completion: .failure(TestError.noData))
                }
            }
        }
    }
}
// MARK: - Codable Model
struct Warp: Decodable {
    let args: Args
}
struct Args: Decodable {
    let result: String
}
