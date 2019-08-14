import XCTest
import Combine
@testable import CombineEx

private let pic1 = "https://avatars1.githubusercontent.com/u/9919?s=200&v=4"
private let pic2 = "https://avatars1.githubusercontent.com/u/9919?s=200&v=4"
private let pic3 = "https://avatars1.githubusercontent.com/u/9919?s=200&v=4"
private let picErr = "https://hahah.com/pic.net.exist"
private let intUrl = "http://httpbin.org/anything?result=123"

var token: AnyCancellable?

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
                return .passThrough { (completion) in
                    DispatchQueue.global().async {
                        if let d = NSData(contentsOf: URL(string: url)!) {
                            completion.send(d as Data)
                            completion.send(completion: .finished)
                        } else {
                            completion.send(completion: .failure(TestError.noData))
                        }
                    }
                }
            }
            let expectSuccessCount = 2
            let expectFailureCount = 1
            token = any(promises).sink(
                receiveCompletion: { _ in
                    token?.cancel()
                    e.fulfill()
                },
                receiveValue: { (result) in
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
            })
        }
    }
    
    func testAnyAB() {
        let a = dataPublisher(for: pic1)
        let b = stringPublisher(for: picErr)
        asyncTest { (e) in
            token = any(a, b).sink(
                receiveCompletion: { _ in
                    token?.cancel()
                    e.fulfill()
                },
                receiveValue: { (value) in
                let aValue = try? value.0.get()
                let bValue = try? value.1.get()
                assert(aValue != nil, "A must not fail")
                assert(bValue == nil, "B must fail")
            })
        }
    }
    
    func testAnyABC() {
        let a = dataPublisher(for: pic1)
        let b = stringPublisher(for: picErr)
        let c = intPublisher(for: intUrl)
        asyncTest { (e) in
            token = any(a, b, c).sink(
                receiveCompletion: { _ in
                    token?.cancel()
                    e.fulfill()
                },
                receiveValue: { (value) in
                    let aValue = try? value.0.get()
                    let bValue = try? value.1.get()
                    let cValue = try? value.2.get()
                    assert(aValue != nil, "A must not fail")
                    assert(bValue == nil, "B must fail")
                    assert(cValue != nil, "C must not fail")
            })
        }
    }
    
    func testAnyABCD() {
        let a = dataPublisher(for: pic1)
        let b = stringPublisher(for: picErr)
        let c = intPublisher(for: intUrl)
        let d = dataPublisher(for: pic2)
        asyncTest { (e) in
            token = any(a, b, c, d).sink(
                receiveCompletion: { _ in
                    token?.cancel()
                    e.fulfill()
                },
                receiveValue: { (value) in
                    let aValue = try? value.0.get()
                    let bValue = try? value.1.get()
                    let cValue = try? value.2.get()
                    let dValue = try? value.3.get()
                    assert(aValue != nil, "A must not fail")
                    assert(bValue == nil, "B must fail")
                    assert(cValue != nil, "C must not fail")
                    assert(dValue != nil, "D must not fail")
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
        let a = AnyPublisher<String, Never>(Just<String>("A"))
        let p = AnyPublisher<String, Never>(Just<String>("P"))
        let p2 = AnyPublisher<String, Never>(Just<String>("P"))
        let l = AnyPublisher<String, Never>(Just<String>("L"))
        let e = AnyPublisher<String, Never>(Just<String>("E"))

        asyncTest { (rr) in
            token = all(a, p, p2, l, e).sink(receiveCompletion: { _ in
                token?.cancel()
                rr.fulfill()
            }, receiveValue: { list in
                let result = list.joined()
                print(result)
                assert(result == "APPLE")
            })
        }
    }
    
    func testAllListError() {
        let a = AnyPublisher<String, AllError>(Result<String, AllError>.Publisher("A").eraseToAnyPublisher())
        let p = AnyPublisher<String, AllError>(Result<String, AllError>.Publisher("P").eraseToAnyPublisher())
        let p2 = AnyPublisher<String, AllError>(Fail<String, AllError>.init(error: .somethingWentWrong))
        let l = AnyPublisher<String, AllError>(Result<String, AllError>.Publisher("L").eraseToAnyPublisher())
        let e = AnyPublisher<String, AllError>(Result<String, AllError>.Publisher("E").eraseToAnyPublisher())

        asyncTest { (rr) in
            token = all(a, p, p2, l, e).sink(receiveCompletion: { info in
                switch info {
                case let .failure(err):
                    print(err)
                    token?.cancel()
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
            token = all(a, b).sink(receiveCompletion: { info in
                switch info {
                case let .failure(error):
                    switch error {
                    case .a: notExpectReachThisLine()
                    case let .b(errB):
                        print(errB)
                        token?.cancel()
                        e.fulfill()
                    }
                case .finished:
                    notExpectReachThisLine()
                }
            }, receiveValue: { (value) in
                notExpectReachThisLine()
            })
        }
    }
    
    func testAllABC() {
        let a = dataPublisher(for: pic1)
        let b = dataPublisher(for: pic2)
        let c = intPublisher(for: intUrl)
        var token: AnyCancellable?
        asyncTest { (e) in
            token = all(a, b, c).sink(
                receiveCompletion: { (_) in },
                receiveValue: { (_) in
                    token?.cancel()
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
            token = all(a, b, c, d).sink(receiveCompletion: { (_) in
                token?.cancel()
            }, receiveValue: { (value) in
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
        let itemA = AnyPublisher<String, AllError>.passThrough { (completion) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                completion.send("Lincoln")
                completion.send(completion: .finished)
            }
        }
        
        let itemB = AnyPublisher<String, AllError>.passThrough { (completion) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                completion.send("Alice")
                completion.send(completion: .finished)
            }
        }
        
        asyncTest { (e) in
            token = race(itemA, itemB).sink(receiveCompletion: { _ in
                e.fulfill()
            }, receiveValue: { result in
                assert(result == "Lincoln")
            })
        }
    }
    
    func testRaceListError() {
        let itemA = AnyPublisher<String, RaceError>.passThrough { (completion) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                completion.send(completion: .failure(.oops))
            }
        }
        
        let itemB = AnyPublisher<String, RaceError>.passThrough { (completion) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                completion.send(completion: .failure(.oops))
            }
        }
        
        asyncTest { (e) in
            token = race(itemA, itemB).sink(receiveCompletion: { info in
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
        return .passThrough { (completion) in
            DispatchQueue.global(qos: .background).async {
                if let d = NSData(contentsOf: URL(string: url)!) {
                    completion.send(d as Data)
                    completion.send(completion: .finished)
                } else {
                    completion.send(completion: .failure(TestError.noData))
                }
            }
        }
    }
    
    private func stringPublisher(for url: String) -> AnyPublisher<String, TestError> {
        return .passThrough { (completion) in
            DispatchQueue.global(qos: .utility).async {
                if let d = NSData(contentsOf: URL(string: url)!) {
                    completion.send(d.description)
                    completion.send(completion: .finished)
                } else {
                    completion.send(completion: .failure(TestError.noData))
                }
            }
        }
    }
    
    private func intPublisher(for url: String) -> AnyPublisher<Int, TestError> {
        return .passThrough { (completion) in
            DispatchQueue.global(qos: .userInitiated).async {
                if let d = NSData(contentsOf: URL(string: url)!) {
                    let result = try! JSONDecoder().decode(Warp.self, from: d as Data)
                    completion.send(Int(result.args.result)!)
                    completion.send(completion: .finished)
                } else {
                    completion.send(completion: .failure(TestError.noData))
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
