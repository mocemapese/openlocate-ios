//
//  HttpClient.swift
//
//  Copyright (c) 2017 OpenLocate
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

typealias HttpClientCompletionHandler = (HttpRequest, HttpResponse) -> Void

typealias Parameters = Any
typealias QueryParameters = [String: String]
typealias ResponseBody = Any
typealias StatusCode = Int

typealias JsonDictionary = [String: Any]
typealias JsonArray = [Any]

// URLSessionProtocol

typealias DataTaskResult = (Data?, URLResponse?, Error?) -> Void

protocol URLSessionProtocol {
    func dataTask(with request: URLRequest, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol
}

extension URLSession: URLSessionProtocol {
    func dataTask(with request: URLRequest, completionHandler: @escaping DataTaskResult) -> URLSessionDataTaskProtocol {
        return (dataTask(with: request,
                         completionHandler: completionHandler) as URLSessionDataTask) as URLSessionDataTaskProtocol
    }
}

protocol URLSessionDataTaskProtocol {
    func resume()
}

extension URLSessionDataTask: URLSessionDataTaskProtocol { }

// Http Client protocols

struct URLRequestParamters {
    let url: String
    let params: Parameters?
    let queryParams: QueryParameters?
    let additionalHeaders: Headers?
}

protocol Postable {
    func post(
        parameters: URLRequestParamters,
        success: @escaping HttpClientCompletionHandler,
        failure: @escaping HttpClientCompletionHandler) throws
}

protocol Getable {
    func get(
        parameters: URLRequestParamters,
        success: @escaping HttpClientCompletionHandler,
        failure: @escaping HttpClientCompletionHandler) throws
}

enum HttpClientError: Error {
    case badRequest
}

// Used to make REST API calls to the backend.
protocol HttpClientType: Postable, Getable {}

final class HttpClient: HttpClientType {
    private let session: URLSessionProtocol

    init(urlSession: URLSessionProtocol = URLSession(configuration: .default)) {
        self.session = urlSession
    }

    // User-Agent Header; see https://tools.ietf.org/html/rfc7231#section-5.5.3
    // Example: `iOS Example/1.0 (org.openlocate.iOS-Example; build:1; iOS 11.0.0) OpenLocate/1.0.0`
    var userAgent: String = {
        if let info = Bundle.main.infoDictionary {
            let executable = info[kCFBundleExecutableKey as String] as? String ?? "Unknown"
            let bundle = info[kCFBundleIdentifierKey as String] as? String ?? "Unknown"
            let appVersion = info["CFBundleShortVersionString"] as? String ?? "Unknown"
            let appBuild = info[kCFBundleVersionKey as String] as? String ?? "Unknown"

            let osNameVersion: String = {
                let version = ProcessInfo.processInfo.operatingSystemVersion
                let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"

                let osName: String = {
                    #if os(iOS)
                        return "iOS"
                    #else
                        return "Unknown"
                    #endif
                }()

                return "\(osName) \(versionString)"
            }()

            let openLocateVersion: String = {
                guard let openLocateInfo = Bundle(for: OpenLocate.self).infoDictionary,
                    let build = openLocateInfo["CFBundleShortVersionString"] else {
                        return "Unknown"
                }
                return "OpenLocate/\(build)"
            }()

            return "\(executable)/\(appVersion) (\(bundle); build:\(appBuild); \(osNameVersion)) \(openLocateVersion)"
        }
        return "OpenLocate"
    }()
}

extension HttpClient {
    private func execute(_ request: HttpRequest) throws {
        guard var urlRequest = URLRequest(request) else {
            // if the url could not be created, throw an error
            throw HttpClientError.badRequest
        }

        // make url request from request
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.addValue(userAgent, forHTTPHeaderField: "User-Agent")

        // create the task object with the request
        let task = session.dataTask(with: urlRequest) { data, response, error in
            self.onTaskExecute(
                with: request,
                data: data,
                response: response,
                error: error
            )
        }

        // execute the task
        task.resume()
    }

    private func onTaskExecute(
        with request: HttpRequest,
        data: Data?,
        response urlResponse: URLResponse?,
        error: Error?) {
        // cast response as HTTPURLResponse and get it's status code
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            if let failure = request.failureCompletion {
                failure(request, HttpResponse.Builder()
                    .set(statusCode: 400)
                    .build()
                )
            }
            return
        }

        let code = httpResponse.statusCode
        var body: ResponseBody?

        if let data = data, !data.isEmpty {
            body = try? JSONSerialization.jsonObject(with: data,
                                                     options: .mutableContainers)
        }

        let response = HttpResponse.Builder()
            .set(statusCode: code)
            .set(body: body)
            .set(error: error)
            .build()

        if let success = request.successCompletion, response.success {
            success(request, response)
            return
        }

        if let failure = request.failureCompletion {
            failure(request, response)
        }
    }
}

// Implement Postable protocol methods
extension HttpClient {
    func post(
        parameters: URLRequestParamters,
        success: @escaping HttpClientCompletionHandler,
        failure: @escaping HttpClientCompletionHandler) throws {
        let request = HttpRequest.Builder()
            .set(url: parameters.url)
            .set(method: .post)
            .set(params: parameters.params)
            .set(queryParams: parameters.queryParams)
            .set(additionalHeaders: parameters.additionalHeaders)
            .set(success: success)
            .set(failure: failure)
            .build()

        try execute(request)
    }

    func get(
        parameters: URLRequestParamters,
        success: @escaping HttpClientCompletionHandler,
        failure: @escaping HttpClientCompletionHandler) throws {
        let request = HttpRequest.Builder()
            .set(url: parameters.url)
            .set(method: .get)
            .set(params: parameters.params)
            .set(queryParams: parameters.queryParams)
            .set(additionalHeaders: parameters.additionalHeaders)
            .set(success: success)
            .set(failure: failure)
            .build()

        try execute(request)
    }
}
