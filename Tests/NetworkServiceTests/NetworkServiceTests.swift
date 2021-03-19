import XCTest
@testable import NetworkService

final class NetworkServiceTests: XCTestCase {
    
    class URLSessionMock: URLSessionProvider {

        var nextData: Data?
        var nextError: Error?
        
        func successHttpURLResponse(request: URLRequest) -> URLResponse {

            return HTTPURLResponse(url: request.url!,
                                   statusCode: 200,
                                   httpVersion: "HTTP/1.1",
                                   headerFields: nil)!
        }
        
        func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTaskProvider {

            completionHandler(nextData, successHttpURLResponse(request: request), nextError)

            return URLSessionDataTaskMock()
        }
    }
    
    class URLSessionDataTaskMock: URLSessionDataTaskProvider {

        func resume() {}

    }
    
    struct Todo: Codable, Equatable {
        
        static func == (lhs: Todo, rhs: Todo) -> Bool {
            let idCondition = lhs.id == rhs.id
            let titleCondition = lhs.title == rhs.title
            let bodyCondition = lhs.body == rhs.body
            let userIdCondition = lhs.body == rhs.body
            
            return idCondition && titleCondition && bodyCondition && userIdCondition
        }
        
        var id: Int?
        var title: String
        var body: String
        var userId: Int
    }
    
    let todo = Todo(id: nil, title: "Test", body: "Test", userId: 1)

    let resource = Resource(method: .post,
                            url: URL(string: "https://google.com")!,
                            body: "Sample".data(using: .utf8),
                            headers: ["overriding": "newValue"])
    
    func testRequestCreation() {
        
        let defaultHeaders = [
            "token": "token",
            "overriding": "startValue"
        ]
        
        let networkService = NetworkService(defaultHeaders: defaultHeaders)
        
        XCTAssertEqual(networkService.defaultHeaders, defaultHeaders)
        
        let request = networkService.createRequest(for: resource)
        
        let assertingHeaders = [
            "token": "token",
            "overriding": "newValue"
        ]
        
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url, URL(string: "https://google.com")!)
        XCTAssertEqual(request.httpBody, "Sample".data(using: .utf8))
        XCTAssertEqual(request.allHTTPHeaderFields, assertingHeaders)

    }
    
    func testDecode() {

        let networkService = NetworkService()

        let encoder = JSONEncoder()

        guard let data = try? encoder.encode(todo) else {
            return
        }

        networkService.decode(data: data) { (result: Result<Todo, NetworkError>) in
            switch result {
            case .success(let decodedTodo):
                XCTAssertEqual(self.todo, decodedTodo)
            case .failure(let error):
                XCTFail("Test failed: \(error.localizedDescription)")
            }
        }

    }
    
    func testSuccessfulStatusCodes() {
        let networkService = NetworkService()

        networkService.setSuccessfulStatusCodes(0..<300)
        XCTAssertEqual(networkService.successfulStatusCodes, 100..<300)
        
        networkService.setSuccessfulStatusCodes(100..<700)
        XCTAssertEqual(networkService.successfulStatusCodes, 100..<600)
    }
    
    func testPerformRequest() {
        
        let networkService = NetworkService()
        let resource = Resource(method: .get, url: URL(string: "https://mockurl")!)
        
        guard let expectedData = try? JSONEncoder().encode(todo) else {
            return
        }

        let session = URLSessionMock()
        session.nextData = expectedData
        
        networkService.session = session
        
        let request = networkService.createRequest(for: resource)
        
        networkService.executeRequest(request: request, completion: { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(data, expectedData)
            case .failure(_):
                XCTFail()
            }
        })
        
        networkService.performRequest(for: resource) { result in
            switch result {
            case .success(let data):
                XCTAssertEqual(data, expectedData)
            case .failure(_):
                XCTFail()
            }
        }
        
        networkService.performRequest(for: resource, decodingTo: Todo.self) { result in
            switch result {
            case .success(let resultTodo):
                XCTAssertEqual(resultTodo, self.todo)
            case .failure(_):
                XCTFail()
            }
        }

    }

    static var allTests = [
        ("testRequestCreation", testRequestCreation),
        ("testDecode", testDecode),
        ("testSuccessfulStatusCodes", testSuccessfulStatusCodes),
        ("testPerformRequest", testPerformRequest),
    ]

}
