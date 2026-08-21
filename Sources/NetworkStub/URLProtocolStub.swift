import Foundation

/// Intercepts every request on a `URLSession` configured with it, so any
/// `URLSession`-based network client can be tested against canned responses without
/// touching the network. Works with any app's networking layer — the only
/// requirement is that the client accepts an injectable `URLSession`.
///
/// ```swift
/// let configuration = URLSessionConfiguration.ephemeral
/// configuration.protocolClasses = [URLProtocolStub.self]
/// let session = URLSession(configuration: configuration)
///
/// URLProtocolStub.handler = { request in
///     let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
///     return (response, canned)
/// }
/// ```
public final class URLProtocolStub: URLProtocol {
    public static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    // `class`, not `static`: both override URLProtocol's own class methods, and Swift
    // doesn't allow `static` to override a superclass's `class` member.
    // swiftlint:disable:next static_over_final_class
    public override class func canInit(with request: URLRequest) -> Bool { true }
    // swiftlint:disable:next static_over_final_class
    public override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    public override func startLoading() {
        guard let handler = URLProtocolStub.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    public override func stopLoading() {}
}
