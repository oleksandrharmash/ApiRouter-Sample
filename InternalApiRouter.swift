//
//  InternalApiRouter.swift
//
//  Created by Oleksandr Harmash
//  Copyright © Oleksandr Harmash. All rights reserved.
//

import Alamofire
import SwiftProtobuf

protocol InternalApiRouter: ApiRouter {
    typealias EmptyRequestCompletion = (RequestResult<EmptyResponse>) -> ()
    
    typealias UploadProgressHandler = (closure: Request.ProgressHandler, queue: DispatchQueue)
    typealias MultipartFormDataCallback = ((MultipartFormData) -> ())
    
    var baseURL: String { get }
    var apiVersion: String { get }
    var apiRelativePath: String { get }
}

extension InternalApiRouter where Self: InternalApiRouter {
    @discardableResult
    func request<T: Message>(
        path: String,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil,
        completionHandler: RequestCompletion<T>? = nil) -> DataRequest {
        
        let fullPath = String(format: "%@/%@", apiRelativePath, path)
        let request = self.request(path: fullPath, method: method, encoding: encoding, headers: headers)
        
        guard let completion = completionHandler else { return request }
        
        request.validate().responseData(completionHandler: { response in
            self.process(response: response, completion: completion)
        })
        
        return request
    }
    
    func upload<T: Message>(
        multipartFormData: @escaping MultipartFormDataCallback,
        path: String,
        method: HTTPMethod = .post,
        headers: HTTPHeaders? = nil,
        uploadProgress: UploadProgressHandler? = nil,
        completionHandler: @escaping RequestCompletion<T>) {
        
        let fullPath = String(format: "%@/%@", apiRelativePath, path)
        sessionManager.upload(multipartFormData: multipartFormData,
                              to: fullPath,
                              method: method,
                              headers: headers,
                              encodingCompletion: {(result) in
                                switch result {
                                case .success(let request, _, _):
                                    if let progress = uploadProgress {
                                        request.uploadProgress(queue: progress.queue, closure: progress.closure)
                                    }
                                    request.validate().responseData(completionHandler: { (response) in
                                        self.process(response: response, completion: completionHandler)
                                    })
                                    
                                case .failure(let error):
                                    let reason: FailReason = FailReason(description: error.localizedDescription,
                                                                        field: nil)
                                    completionHandler(RequestResult<T>.fail(errors: [reason]))
                                }
        })
    }
}

private extension InternalApiRouter {
    func process<T: Message>(response: DataResponse<Data>, completion: RequestCompletion<T>) {
        switch response.result {
        case .failure(let error):
            var reasons: [FailReason] = []
            if let descriptions: ErrorValidation = response.data?.decodeProtobuf(),
                descriptions.errors.isEmpty == false {
                reasons = descriptions.errors.map {
                    return FailReason(descriptions: $0.messages, field: $0.path)
                }
            } else {
                let reason: FailReason = FailReason(description: error.localizedDescription,
                                                    field: nil)
                reasons.append(reason)
            }
            completion(RequestResult<T>.fail(errors: reasons))
        case .success(let value):
            let data: T? = value.decodeProtobuf()
            completion(RequestResult<T>.success(data: data))
        }
    }
}
