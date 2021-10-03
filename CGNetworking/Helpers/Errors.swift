//
//  NetworkError.swift
//  Networking
//
//  Created by Khalid Rahman on 13/06/2021.
//

import Foundation

public enum NetworkError: Error {
    case error(statusCode: Int, data: Data?)
    case notConnected
    case cancelled
    case generic(Error)
    case urlGeneration
    case serverError(String)
    case tokenExpired
}

public protocol NetworkErrorLogger {
    func log(request: URLRequest)
    func log(responseData data: Data?, response: URLResponse?)
    func log(error: Error)
}

// MARK: - Logger

public final class DefaultNetworkErrorLogger: NetworkErrorLogger {
    public init() { }

    public func log(request: URLRequest) {
        print("-------------")
        print("request: \(request.url!)")
        print("headers: \(request.allHTTPHeaderFields!)")
        print("method: \(request.httpMethod!)")
        if let httpBody = request.httpBody, let result = ((try? JSONSerialization.jsonObject(with: httpBody, options: []) as? [String: AnyObject]) as [String: AnyObject]??) {
            printIfDebug("body: \(String(describing: result))")
        } else if let httpBody = request.httpBody, let resultString = String(data: httpBody, encoding: .utf8) {
            printIfDebug("body: \(String(describing: resultString))")
        }
    }

    public func log(responseData data: Data?, response: URLResponse?) {
        guard let data = data else { return }
        if let dataDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            printIfDebug("responseData: \(String(describing: dataDict))")
        }
    }

    public func log(error: Error) {
        printIfDebug("\(error)")
    }
}

func printIfDebug(_ string: String) {
    #if DEBUG
    print(string)
    #endif
}


// MARK:- Data Transfer Service

public enum DataTransferError: Error {
    case noResponse
    case parsing(Error)
    case networkFailure(NetworkError)
    case resolvedNetworkFailure(Error)
}

// MARK:- Custom Server Error Response

struct ServerErrorResponse: Codable {
    let error       : Errors
    
    enum CodingKeys: String, CodingKey {
        case error  = "error"
    }
}

struct Errors: Codable {
    let errors      : [ServerError]?
    let statusCode  : Int?
    
    enum CodingKeys: String, CodingKey {
        case errors     = "errors"
        case statusCode = "statusCode"
    }
}

struct ServerError: Codable {
    let code        : Int?
    let type        : String?
    let message     : String?
}
