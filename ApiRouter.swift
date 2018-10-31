//
//  ApiRouter.swift
//
//  Created by Oleksandr Harmash
//  Copyright © Oleksandr Harmash. All rights reserved.
//

import Alamofire

typealias RequestCompletion<T: BaseResponse> = (RequestResult<T>) -> ()

protocol ApiRouter {
    var sessionManager: SessionManager { get }
}

extension ApiRouter where Self: ApiRouter {
    func request(
        path: String,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil) -> DataRequest {
        return sessionManager.request(path, method: method, parameters: parameters, encoding: encoding, headers: headers)
    }
}

