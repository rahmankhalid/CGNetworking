//
//  NetworkErrorResponse.swift
//  Networking
//
//  Created by Khalid on 02/08/2021.
//

import Foundation

public enum NetworkErrorResponseCodes: Int {
    case notConnected   = 10001
    case tokenExpired   = 10002
}

public class NetworkErrorResponse {
    
    public static func handleErrorResponse(with error: DataTransferError) -> NSError {
        var userInfo = [String:String]()
        var code     = 0
        
        switch error {
        case .networkFailure(let networkError):
            switch networkError {
            case .cancelled:
                userInfo["description"] = "Network request cancelled"
            case .error(let statusCode, let data):
                userInfo["description"] = "Status Code: \(statusCode) and description: \(String(data: data!, encoding: .utf8) ?? "")"
            case .notConnected:
                code = NetworkErrorResponseCodes.notConnected.rawValue
                userInfo["description"] = "Not connected"
            case .generic(let genericError):
                userInfo["description"] = "Generic error \(genericError)"
            case .serverError(let message):
                userInfo["description"] = "Server Error: \(message)"
            case .tokenExpired:
                code = NetworkErrorResponseCodes.tokenExpired.rawValue
                userInfo["description"] = "Token Expired"
            case .urlGeneration:
                userInfo["description"] = "URL Generation Error"
            }
        case .noResponse:
            userInfo["description"] = "no response"
        case .parsing(let parseError):
            userInfo["description"] = "Parsing Error: \(parseError)"
        case .resolvedNetworkFailure(let networkError):
            userInfo["description"] = "Resolves network failure \(networkError)"
        }
        
        return NSError(domain: "com.cgnetworking.main", code: code, userInfo: userInfo)
    }
    
}
