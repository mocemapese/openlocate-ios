//
//  TcpClient.swift
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

typealias TcpClientCompletionHandler = (TcpRequest, TcpResponse) -> Void

private let timeOut: TimeInterval = 45.0

// URLSessionStreamTaskProtocol

typealias WriteDataTaskResult = (Error?) -> Void

protocol URLSessionStreamTaskProtocol {
    func streamTask(withHostName hostname: String, port: Int) -> URLSessionStreamTaskWriteProtocol
}

extension URLSession: URLSessionStreamTaskProtocol {
    func streamTask(withHostName hostname: String, port: Int) -> URLSessionStreamTaskWriteProtocol {
        return (streamTask(withHostName: hostname, port: port)
            as URLSessionStreamTask) as URLSessionStreamTaskWriteProtocol
    }
}

protocol URLSessionStreamTaskWriteProtocol {
    func write(_ data: Data, timeout: TimeInterval, completionHandler: @escaping WriteDataTaskResult)
    func resume()
}

extension URLSessionStreamTask: URLSessionStreamTaskWriteProtocol { }

// Writeable Protocol

protocol Writeable {
    func write(
        data: String,
        completion: @escaping TcpClientCompletionHandler
    ) throws
}

protocol TcpClientType: Writeable {

}

enum TcpClientError: Error {
    case badData
}

// Tcp Client

final class TcpClient: TcpClientType {

    private let streamTask: URLSessionStreamTaskWriteProtocol

    init(host: String, port: Int, session: URLSessionStreamTaskProtocol = URLSession(configuration: .default)) {
        self.streamTask = session.streamTask(withHostName: host, port: port)
    }

    private func execute(request: TcpRequest) throws {
        guard let data = request.data.data(using: .utf8) else {
                throw TcpClientError.badData
        }

        streamTask.write(data, timeout: timeOut) { error in
            if let completion = request.completionHandler {
                let response = TcpResponse.Builder().set(error: error).build()
                completion(request, response)
            }
        }

        streamTask.resume()
    }
}

extension TcpClient {
    func write(
        data: String,
        completion: @escaping TcpClientCompletionHandler) throws {
        let request = TcpRequest.Builder()
            .set(data: data)
            .set(completionHandler: completion)
            .build()

        try execute(request: request)
    }
}
