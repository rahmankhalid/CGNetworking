//
//  DefaultNetworkService.swift
//  Networking
//
//  Created by Khalid Rahman on 13/06/2021.
//

import Foundation

public final class DefaultNetworkService {
    
    private let config              : NetworkConfigurable
    private let sessionManager      : NetworkSessionManager
    private let logger              : NetworkErrorLogger
    
    public init(config: NetworkConfigurable,
                sessionManager: NetworkSessionManager = DefaultNetworkSessionManager(),
                logger: NetworkErrorLogger = DefaultNetworkErrorLogger()) {
        self.sessionManager = sessionManager
        self.config = config
        self.logger = logger
    }
    
    private func request(request: URLRequest, completion: @escaping CompletionHandler) -> NetworkCancellable {
        let sessionDataTask = sessionManager.request(request) { data, response, requestError in
            
            if let requestError = requestError {
                if let serverError = self.parseApiError(data: data) {
                    completion(.failure(self.handleApiServerErrors(with: serverError)))
                }
                
                var error: NetworkError
                if let response = response as? HTTPURLResponse {
                    error = .error(statusCode: response.statusCode, data: data)
                } else {
                    error = self.resolve(error: requestError)
                }
                
                self.logger.log(error: error)
                completion(.failure(error))
            } else {
                self.logger.log(responseData: data, response: response)
                completion(.success(data))
            }
        }
    
        logger.log(request: request)

        return sessionDataTask
    }
    
    private func multipartRequest(request: URLRequest, completion: @escaping CompletionHandler) -> NetworkCancellable {
        
        let sessionDataTask = sessionManager.request(request) { data, response, requestError in
        
            if let requestError = requestError {
                if let serverError = self.parseApiError(data: data) {
                    completion(.failure(self.handleApiServerErrors(with: serverError)))
                }
                
                var error: NetworkError
                if let response = response as? HTTPURLResponse {
                    error = .error(statusCode: response.statusCode, data: data)
                } else {
                    error = self.resolve(error: requestError)
                }
                
                self.logger.log(error: error)
                completion(.failure(error))
            } else {
                self.logger.log(responseData: data, response: response)
                completion(.success(data))
            }
        }
    
        logger.log(request: request)

        return sessionDataTask
    }
    
    private func resolve(error: Error) -> NetworkError {
        let code = URLError.Code(rawValue: (error as NSError).code)
        switch code {
        case .notConnectedToInternet    : return .notConnected
        case .cancelled                 : return .cancelled
        default                         : return .generic(error)
        }
    }
    
    private func parseApiError(data: Data?) -> ServerError? {
        let defaultError = ServerError(code: 401, type: "", message: "Unknown Error with the server")
        let decoder = JSONDecoder()
        
        if let jsonData = data, let error = try? decoder.decode(ServerErrorResponse.self, from: jsonData) {
            if error.error.errors?.count ?? 0 > 0 {
                return error.error.errors?[0] ?? defaultError
            }
        }
        
        return nil
    }
    
    private func handleApiServerErrors(with error: ServerError) -> NetworkError {
        if let serverCode = error.code {
            
            if Range(NSRange(location: 10001, length: 50))?.contains(serverCode) ?? false {
                return .serverError(error.message ?? "Unknown error")
            }
            
            if Range(NSRange(location: 20001, length: 20))?.contains(serverCode) ?? false {
                return .tokenExpired
            }
        }
        
        return .serverError("There was a problem decoding the network error")
    }
}

extension DefaultNetworkService: NetworkService {
    
    public func request(endpoint: Requestable, completion: @escaping CompletionHandler) -> NetworkCancellable? {
        do {
            let urlRequest = try endpoint.urlRequest(with: config)
            return request(request: urlRequest, completion: completion)
        } catch {
            completion(.failure(.urlGeneration))
            return nil
        }
    }
    
    public func multipartRequest(endpoint: Requestable, completion: @escaping CompletionHandler) -> NetworkCancellable? {
        do {
            var urlRequest = try endpoint.urlRequest(with: config)
            let boundary = "Boundary-\(UUID().uuidString)"
            urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = addHttpBody(endpoint: endpoint, boundary: boundary) as Data
            return request(request: urlRequest, completion: completion)
        } catch {
            completion(.failure(.urlGeneration))
            return nil
        }
    }
}


// MARK: - Default Network Session Manager
// Note: If authorization is needed NetworkSessionManager can be implemented by using,
// for example, Alamofire SessionManager with its RequestAdapter and RequestRetrier.
// And it can be incjected into NetworkService instead of default one.

public class DefaultNetworkSessionManager: NetworkSessionManager {
    public init() {}
    public func request(_ request: URLRequest,
                        completion: @escaping CompletionHandler) -> NetworkCancellable {
        let task = URLSession.shared.dataTask(with: request, completionHandler: completion)
        task.resume()
        return task
    }
    
    public func multipartRequest(_ request: URLRequest, completion: @escaping CompletionHandler) -> NetworkCancellable {
        let task = URLSession.shared.dataTask(with: request, completionHandler: completion)
        task.resume()
        return task
    }
}

// MARK:- Helpers

extension DefaultNetworkService {
    func convertFormField(named name: String, value: String, using boundary: String) -> String {
      var fieldString = "--\(boundary)\r\n"
      fieldString += "Content-Disposition: form-data; name=\"\(name)\"\r\n"
      fieldString += "\r\n"
      fieldString += "\(value)\r\n"

      return fieldString
    }

    func convertFileData(fieldName: String, fileName: String, mimeType: String, fileData: Data, using boundary: String) -> Data {
      let data = NSMutableData()

      data.appendString("--\(boundary)\r\n")
      data.appendString("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n")
      data.appendString("Content-Type: \(mimeType)\r\n\r\n")
      data.append(fileData)
      data.appendString("\r\n")

      return data as Data
    }
    
    func addHttpBody(endpoint: Requestable, boundary: String) -> NSMutableData {
        let httpBody = NSMutableData()

        if endpoint.formFields.count > 0 {
            for (key, value) in endpoint.formFields {
                httpBody.appendString(convertFormField(named: key, value: "\(value)", using: boundary))
            }
        }
        
        if endpoint.imageData.count > 0 {
            for (key, value) in endpoint.imageData {
                httpBody.append(convertFileData(fieldName: key,
                                                fileName: "\(arc4random()).jpeg",
                                                mimeType: "image/jpg",
                                                fileData: value,
                                                using: boundary))
            }
        }
        
        httpBody.appendString("--\(boundary)--")

        return httpBody
    }
}

extension NSMutableData {
  func appendString(_ string: String) {
    if let data = string.data(using: .utf8) {
      self.append(data)
    }
  }
}
