import XCTest
import NetworkStub
@testable import QuoteBox

final class QuoteAPIClientTests: XCTestCase {
    private var session: URLSession!

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        session = URLSession(configuration: configuration)
    }

    override func tearDown() {
        URLProtocolStub.handler = nil
        session = nil
        super.tearDown()
    }

    func testFetchRandomQuoteDecodesResponse() async throws {
        let json = """
        { "id": 42, "quote": "Stubbed wisdom.", "author": "Someone" }
        """.data(using: .utf8)!

        URLProtocolStub.handler = { request in
            XCTAssertEqual(request.url?.host, "dummyjson.com")
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, json)
        }

        let client = QuoteAPIClient(session: session)
        let quote = try await client.fetchRandomQuote()

        XCTAssertEqual(quote, Quote(id: 42, quote: "Stubbed wisdom.", author: "Someone"))
    }

    func testFetchRandomQuoteThrowsRequestFailedOnServerError() async {
        URLProtocolStub.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data())
        }

        let client = QuoteAPIClient(session: session)

        do {
            _ = try await client.fetchRandomQuote()
            XCTFail("Expected fetchRandomQuote to throw")
        } catch let error as APIError {
            XCTAssertEqual(error, .requestFailed)
        } catch {
            XCTFail("Expected APIError.requestFailed, got \(error)")
        }
    }

    func testFetchRandomQuoteThrowsDecodingFailedOnMalformedJSON() async {
        URLProtocolStub.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, "not json".data(using: .utf8)!)
        }

        let client = QuoteAPIClient(session: session)

        do {
            _ = try await client.fetchRandomQuote()
            XCTFail("Expected fetchRandomQuote to throw")
        } catch let error as APIError {
            XCTAssertEqual(error, .decodingFailed)
        } catch {
            XCTFail("Expected APIError.decodingFailed, got \(error)")
        }
    }
}
