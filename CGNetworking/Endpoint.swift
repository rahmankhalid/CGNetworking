//
//  Endpoint.swift
//  Networking
//
//  Created by Khalid Rahman on 13/06/2021.
//

import Foundation

public class Endpoint<R>: ResponseRequestable {

    public typealias Response = R

    public let path: String
    public let isFullPath: Bool
    public let method: HTTPMethodType
    public let headerParamaters: [String: String]
    public let queryParametersEncodable: Encodable?
    public let queryParameters: [String: Any]
    public let bodyParamatersEncodable: Encodable?
    public let bodyParamaters: [String: Any]
    public let bodyEncoding: BodyEncoding
    public let responseDecoder: ResponseDecoder
    public let formFields: [String : Any]
    public let imageData: [String : Data]

    public init(path: String,
         isFullPath: Bool = false,
         method: HTTPMethodType,
         headerParamaters: [String: String] = [:],
         queryParametersEncodable: Encodable? = nil,
         queryParameters: [String: Any] = [:],
         bodyParamatersEncodable: Encodable? = nil,
         bodyParamaters: [String: Any] = [:],
         bodyEncoding: BodyEncoding = .jsonSerializationData,
         responseDecoder: ResponseDecoder = JSONResponseDecoder(),
         formFields: [String:Any] = [:],
         imageData: [String:Data] = [:]) {
        self.path = path
        self.isFullPath = isFullPath
        self.method = method
        self.headerParamaters = headerParamaters
        self.queryParametersEncodable = queryParametersEncodable
        self.queryParameters = queryParameters
        self.bodyParamatersEncodable = bodyParamatersEncodable
        self.bodyParamaters = bodyParamaters
        self.bodyEncoding = bodyEncoding
        self.responseDecoder = responseDecoder
        self.formFields = formFields
        self.imageData = imageData
    }
}
