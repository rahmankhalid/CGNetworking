//
//  NetworkService.swift
//  Networking
//
//  Created by Khalid Rahman on 13/06/2021.
//

import Foundation

/// Cancel the network request
public protocol NetworkCancellable {
    func cancel()
}

extension URLSessionTask: NetworkCancellable { }

/// Contract for a network service
///
/// - CompletionHandler: Completion handler which takes its a custom Result
/// - Request: Takes custom requestable and completion handler
public protocol NetworkService {
    typealias CompletionHandler = (Result<Data?, NetworkError>) -> Void
    
    func request(endpoint: Requestable, completion: @escaping CompletionHandler) -> NetworkCancellable?
    
    func multipartRequest(endpoint: Requestable, completion: @escaping CompletionHandler) -> NetworkCancellable?
}

/// Contract for a network session manager
///
/// - CompletionHandler: Completion handler which takes its a custom Result
/// - Request: Takes custom requestable and completion handler

public protocol NetworkSessionManager {
    typealias CompletionHandler = (Data?, URLResponse?, Error?) -> Void
    
    func request(_ request: URLRequest, completion: @escaping CompletionHandler) -> NetworkCancellable
    
    func multipartRequest(_ request: URLRequest, completion: @escaping CompletionHandler) -> NetworkCancellable
}
