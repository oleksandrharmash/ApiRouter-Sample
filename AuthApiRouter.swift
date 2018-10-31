//
//  AuthApiRouter.swift
//
//  Created by Oleksandr Harmash
//  Copyright © Oleksandr Harmash. All rights reserved.
//

import UIKit

protocol AuthApiRouter: InternalApiRouter {
    func validate(username: String, email: String?, completion: @escaping EmptyRequestCompletion)
   
    func signup(username: String, email: String?,
                openKey: HDPubKeyModel, password: Cryptable,
                completion: @escaping RequestCompletion<LoginSuccessRS>)
   
    func login(username: String,
               password: Cryptable,
               completion: @escaping RequestCompletion<LoginSuccessRS>)
    
    func logout(completion: EmptyRequestCompletion?)
}

extension AuthApiRouter {
    var apiGroupPath: String { return "auth" }
    
    func validate(username: String, email: String?, completion: @escaping EmptyRequestCompletion) {
        let path = String(format: "%@/validation", apiGroupPath)
        let req = ValidationRQ.with {
            $0.username = username
            if let email = email {
                $0.email = email
            }
            $0.uid = UIDevice.uid
        }

        request(path: path, method: .post, encoding: LQParameterEncoding(object: req), completionHandler: {(result: RequestResult<EmptyResponse>) in
            completion(result)
        })
    }
    
    func signup(username: String, email: String?,
                openKey: HDPubKeyModel, password: Cryptable,
                completion: @escaping RequestCompletion<LoginSuccessRS>) {
        let path = String(format: "%@/registration", apiGroupPath)
        let req = RegistrationRQ.with {
            $0.username = username
            $0.password = password.decryptedData!.base64EncodedString()
            $0.openKey = openKey.stringValue
            if let email = email {
                $0.email = email
            }
            $0.uid = UIDevice.uid
        }
        
        request(path: path, method: .post, encoding: LQParameterEncoding(object: req)) {(result: RequestResult<LoginSuccessRS>) in
            completion(result)
        }
    }

    func login(username: String, password: Cryptable, completion: @escaping RequestCompletion<LoginSuccessRS>) {
        let path = String(format: "%@/login", apiGroupPath)
        let req = LoginRQ.with {
            $0.username = username
            $0.password = password.decryptedData!.base64EncodedString()
        }
        
        request(path: path, method: .post, encoding: LQParameterEncoding(object: req)) { (result: RequestResult<LoginSuccessRS>) in
            completion(result)
        }
    }
    
    func logout(completion: EmptyRequestCompletion? = nil) {
        let path = String(format: "%@/logout", apiGroupPath)
        
        request(path: path, method: .post) { (result: RequestResult<EmptyResponse>) in
            completion?(result)
        }
    }

}
