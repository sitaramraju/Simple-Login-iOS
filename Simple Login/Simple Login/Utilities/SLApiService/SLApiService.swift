//
//  SLApiService.swift
//  Simple Login
//
//  Created by Thanh-Nhon Nguyen on 10/01/2020.
//  Copyright © 2020 SimpleLogin. All rights reserved.
//

import Foundation
import Alamofire

// MARK: Login
extension SLApiService {
    static func login(email: String, password: String, completion: @escaping (Result<UserLogin, SLError>) -> Void) {
        let parameters = ["email" : email, "password" : password, "device" : UIDevice.current.name]
        
        AF.request("\(BASE_URL)/api/auth/login", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil, interceptor: nil).response { response in
            
            guard let data = response.data else {
                completion(.failure(.noData))
                return
            }
            
            guard let statusCode = response.response?.statusCode else {
                completion(.failure(.unknownResponseStatusCode))
                return
            }
            
            switch statusCode {
            case 200:
                do {
                    let userLogin = try UserLogin(fromData: data)
                    completion(.success(userLogin))
                } catch let error {
                    completion(.failure(error as! SLError))
                }
                
            case 400: completion(.failure(.emailOrPasswordIncorrect))
            case 500: completion(.failure(.internalServerError))
            case 502: completion(.failure(.badGateway))
            default: completion(.failure(.unknownErrorWithStatusCode(statusCode: statusCode)))
            }
        }
    }
    
    static func verifyMFA(mfaKey: String, mfaToken: String, completion: @escaping (Result<ApiKey, SLError>) -> Void) {
        let parameters = ["mfa_token" : mfaToken, "mfa_key" : mfaKey, "device" : UIDevice.current.name]
        
        AF.request("\(BASE_URL)/api/auth/mfa", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil, interceptor: nil).response { response in
            
            guard let data = response.data else {
                completion(.failure(.noData))
                return
            }
            
            guard let statusCode = response.response?.statusCode else {
                completion(.failure(.unknownResponseStatusCode))
                return
            }
            
            switch statusCode {
            case 200:
                do {
                    let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
                    
                    if let apiKey = jsonDictionary?["api_key"] as? String {
                        completion(.success(apiKey))
                    } else {
                        completion(.failure(.failToSerializeJSONData))
                    }
                    
                } catch {
                    completion(.failure(.unknownError(error: error)))
                }
                
            case 400: completion(.failure(.wrongTotpToken))
            case 500: completion(.failure(.internalServerError))
            case 502: completion(.failure(.badGateway))
            default: completion(.failure(.unknownErrorWithStatusCode(statusCode: statusCode)))
            }
        }
    }
    
    static func forgotPassword(email: String, completion: @escaping () -> Void) {
        AF.request("\(BASE_URL)/api/auth/forgot_password", method: .post, parameters: ["email": email], encoding: JSONEncoding.default, headers: nil, interceptor: nil).response { response in
            completion()
        }
    }
    
    static func fetchUserInfo(apiKey: ApiKey, completion: @escaping (Result<UserInfo, SLError>) -> Void) {
        let headers: HTTPHeaders = ["Authentication": apiKey]
        
        AF.request("\(BASE_URL)/api/user_info", method: .get, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).response { response in
            
            switch response.result {
            case .success(let data):
                switch response.response?.statusCode {
                case 200:
                    guard let data = data else {
                        completion(.failure(.noData))
                        return
                    }
                    
                    do {
                        let userInfo = try UserInfo(fromData: data)
                        completion(.success(userInfo))
                    } catch let error as SLError {
                        completion(.failure(error))
                    } catch {
                        completion(.failure(.unknownError(error: error)))
                    }
                    
                case 401: completion(.failure(.invalidApiKey))
                case 500: completion(.failure(.internalServerError))
                case 502: completion(.failure(.badGateway))
                default: completion(.failure(.unknownErrorWithStatusCode(statusCode: response.response?.statusCode ?? 0)))
                }
                
            case .failure(let error):
                completion(.failure(.alamofireError(error: error)))
            }
        }
    }
}

// MARK: - Sign Up
extension SLApiService {
    static func signUp(email: String, password: String, completion: @escaping (Result<Any?, SLError>) -> Void) {
        let parameters = ["email" : email, "password" : password]
        
        AF.request("\(BASE_URL)/api/auth/register", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil, interceptor: nil).response { response in
            
            guard let data = response.data else {
                completion(.failure(.noData))
                return
            }
            
            guard let statusCode = response.response?.statusCode else {
                completion(.failure(.unknownResponseStatusCode))
                return
            }
            
            switch statusCode {
            case 200: completion(.success(nil))
                
            case 400:
                do {
                    let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : Any]
                    
                    if let error = jsonDictionary?["error"] as? String {
                        completion(.failure(.badRequest(description: error)))
                    } else {
                        completion(.failure(.failToSerializeJSONData))
                    }
                    
                } catch {
                    completion(.failure(.failToSerializeJSONData))
                }
            case 500: completion(.failure(.internalServerError))
            case 502: completion(.failure(.badGateway))
            default: completion(.failure(.unknownErrorWithStatusCode(statusCode: statusCode)))
            }
        }
    }
    
    static func verifyEmail(email: String, code: String, completion: @escaping (Result<Any?, SLError>) -> Void) {
        let parameters = ["email" : email, "code" : code]
        
        AF.request("\(BASE_URL)/api/auth/activate", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil, interceptor: nil).response { response in
            
            guard let _ = response.data else {
                completion(.failure(.noData))
                return
            }
            
            guard let statusCode = response.response?.statusCode else {
                completion(.failure(.unknownResponseStatusCode))
                return
            }
            
            switch statusCode {
            case 200: completion(.success(nil))
            case 400: completion(.failure(.wrongVerificationCode))
            case 410: completion(.failure(.reactivationNeeded))
            case 500: completion(.failure(.internalServerError))
            case 502: completion(.failure(.badGateway))
            default: completion(.failure(.unknownErrorWithStatusCode(statusCode: statusCode)))
            }
        }
    }
    
    static func reactivate(email: String, completion: @escaping (Result<Any?, SLError>) -> Void) {
        let parameters = ["email" : email]
        
        AF.request("\(BASE_URL)/api/auth/reactivate", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil, interceptor: nil).response { response in
            
            guard let _ = response.data else {
                completion(.failure(.noData))
                return
            }
            
            guard let statusCode = response.response?.statusCode else {
                completion(.failure(.unknownResponseStatusCode))
                return
            }
            
            switch statusCode {
            case 200: completion(.success(nil))
            case 500: completion(.failure(.internalServerError))
            case 502: completion(.failure(.badGateway))
            default: completion(.failure(.unknownErrorWithStatusCode(statusCode: statusCode)))
            }
        }
    }
}

// MARK: - Alias
extension SLApiService {
    static func fetchAliases(apiKey: ApiKey, page: Int, searchTerm: String? = nil, completion: @escaping (Result<[Alias], SLError>) -> Void) {
        let headers: HTTPHeaders = ["Authentication": apiKey]
        
        let method: HTTPMethod
        let parameters: [String: Any]?
        if let searchTerm = searchTerm {
            parameters = ["query": searchTerm]
            method = .post
        } else {
            parameters = nil
            method = .get
        }
        
        
        AF.request("\(BASE_URL)/api/v2/aliases?page_id=\(page)", method: method, parameters: parameters, encoding: JSONEncoding.default, headers: headers, interceptor: nil).response { response in
            
            guard let statusCode = response.response?.statusCode else {
                completion(.failure(.unknownResponseStatusCode))
                return
            }
            
            switch statusCode {
            case 200:
                guard let data = response.data else {
                    completion(.failure(.noData))
                    return
                }
                
                do {
                    let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : Any]
                    
                    if let aliasDictionaries = jsonDictionary?["aliases"] as? [[String : Any]] {
                        var aliases: [Alias] = []
                        try aliasDictionaries.forEach { (dictionary) in
                            do {
                                try aliases.append(Alias(fromDictionary: dictionary))
                            } catch let error as SLError {
                                completion(.failure(error))
                                return
                            }
                        }
                        
                        completion(.success(aliases))
                        
                    } else {
                        completion(.failure(.failToSerializeJSONData))
                    }
                    
                } catch {
                    completion(.failure(.failToSerializeJSONData))
                }
                
            case 400: completion(.failure(.badRequest(description: "page_id must be provided in request query.")))
            case 401: completion(.failure(.invalidApiKey))
            case 500: completion(.failure(.internalServerError))
            case 502: completion(.failure(.badGateway))
            default: completion(.failure(.unknownErrorWithStatusCode(statusCode: statusCode)))
            }
        }
    }
    
    static func fetchAliasActivities(apiKey: ApiKey, aliasId: Alias.Identifier, page: Int, completion: @escaping (Result<[AliasActivity], SLError>) -> Void) {
        let headers: HTTPHeaders = ["Authentication": apiKey]
        
        AF.request("\(BASE_URL)/api/aliases/\(aliasId)/activities?page_id=\(page)", method: .get, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).response { response in
            
            guard let statusCode = response.response?.statusCode else {
                completion(.failure(.unknownResponseStatusCode))
                return
            }
            
            switch statusCode {
            case 200:
                guard let data = response.data else {
                    completion(.failure(.noData))
                    return
                }
                
                do {
                    let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : Any]
                    
                    if let activityDictionaries = jsonDictionary?["activities"] as? [[String : Any]] {
                        var activities: [AliasActivity] = []
                        try activityDictionaries.forEach { (dictionary) in
                            do {
                                try activities.append(AliasActivity(fromDictionary: dictionary))
                            } catch let error as SLError {
                                completion(.failure(error))
                                return
                            }
                        }
                        
                        completion(.success(activities))
                        
                    } else {
                        completion(.failure(.failToSerializeJSONData))
                    }
                    
                } catch {
                    completion(.failure(.failToSerializeJSONData))
                }
                
            case 400: completion(.failure(.badRequest(description: "page_id must be provided in request query.")))
            case 401: completion(.failure(.invalidApiKey))
            case 500: completion(.failure(.internalServerError))
            case 502: completion(.failure(.badGateway))
            default: completion(.failure(.unknownErrorWithStatusCode(statusCode: statusCode)))
            }
        }
    }
    
    static func randomAlias(apiKey: ApiKey, randomMode: RandomMode, completion: @escaping (Result<Alias, SLError>) -> Void) {
        let headers: HTTPHeaders = ["Authentication": apiKey]
        
        AF.request("\(BASE_URL)/api/alias/random/new?mode=\(randomMode.rawValue)", method: .post, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).response { response in
            
            guard let statusCode = response.response?.statusCode else {
                completion(.failure(.unknownResponseStatusCode))
                return
            }
            
            switch statusCode {
            case 201:
                guard let data = response.data else {
                    completion(.failure(.noData))
                    return
                }
                
                do {
                    let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : Any]
                    
                    if let jsonDictionary = jsonDictionary {
                        do {
                            let alias = try Alias(fromDictionary: jsonDictionary)
                            completion(.success(alias))
                        } catch let error as SLError {
                            completion(.failure(error))
                        }
                    }
                    
                } catch {
                    completion(.failure(.failToSerializeJSONData))
                }
                
            case 401: completion(.failure(.invalidApiKey))
            case 500: completion(.failure(.internalServerError))
            case 502: completion(.failure(.badGateway))
            default: completion(.failure(.unknownErrorWithStatusCode(statusCode: statusCode)))
            }
        }
    }
    
    static func toggleAlias(apiKey: ApiKey, id: Alias.Identifier, completion: @escaping (Result<Bool, SLError>) -> Void) {
        let headers: HTTPHeaders = ["Authentication": apiKey]
        
        AF.request("\(BASE_URL)/api/aliases/\(id)/toggle", method: .post, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).response { response in
            
            guard let statusCode = response.response?.statusCode else {
                completion(.failure(.unknownResponseStatusCode))
                return
            }
            
            switch statusCode {
            case 200:
                guard let data = response.data else {
                    completion(.failure(.noData))
                    return
                }
                
                do {
                    let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : Any]
                    
                    if let enabled = jsonDictionary?["enabled"] as? Bool {
                        completion(.success(enabled))
                    } else {
                        completion(.failure(.failToParseObject(objectName: "toggle alias status")))
                    }
                    
                } catch {
                    completion(.failure(.failToSerializeJSONData))
                }
                
            case 401: completion(.failure(.invalidApiKey))
            case 500: completion(.failure(.internalServerError))
            case 502: completion(.failure(.badGateway))
            default: completion(.failure(.unknownErrorWithStatusCode(statusCode: statusCode)))
            }
        }
    }
    
    static func deleteAlias(apiKey: ApiKey, id: Alias.Identifier, completion: @escaping (Result<Any?, SLError>) -> Void) {
        let headers: HTTPHeaders = ["Authentication": apiKey]
        
        AF.request("\(BASE_URL)/api/aliases/\(id)", method: .delete, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).response { response in
            
            guard let statusCode = response.response?.statusCode else {
                completion(.failure(.unknownResponseStatusCode))
                return
            }
            
            switch statusCode {
            case 200:
                guard let data = response.data else {
                    completion(.failure(.noData))
                    return
                }
                
                do {
                    let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : Any]
                    
                    if let deleted = jsonDictionary?["deleted"] as? Bool {
                        deleted ? completion(.success(nil)) : completion(.failure(.failToDelete(objectName: "Alias")))
                    } else {
                        completion(.failure(.failToParseObject(objectName: "delete alias")))
                    }
                    
                } catch {
                    completion(.failure(.failToSerializeJSONData))
                }
                
            case 401: completion(.failure(.invalidApiKey))
            case 500: completion(.failure(.internalServerError))
            case 502: completion(.failure(.badGateway))
            default: completion(.failure(.unknownErrorWithStatusCode(statusCode: statusCode)))
            }
        }
    }
    
    static func updateAliasNote(apiKey: ApiKey, id: Alias.Identifier, note: String?, completion: @escaping (Result<Any?, SLError>) -> Void) {
        let headers: HTTPHeaders = ["Authentication": apiKey]
        
        AF.request("\(BASE_URL)/api/aliases/\(id)", method: .put, parameters: ["note": note ?? ""], encoding: JSONEncoding.default, headers: headers, interceptor: nil).response { response in
            
            guard let statusCode = response.response?.statusCode else {
                completion(.failure(.unknownResponseStatusCode))
                return
            }
            
            switch statusCode {
            case 200: completion(.success(nil))
            case 401: completion(.failure(.invalidApiKey))
            case 500: completion(.failure(.internalServerError))
            case 502: completion(.failure(.badGateway))
            default: completion(.failure(.unknownErrorWithStatusCode(statusCode: statusCode)))
            }
        }
    }
    
    static func getAlias(apiKey: ApiKey, id: Alias.Identifier, completion: @escaping (Result<Alias, SLError>) -> Void) {
        let headers: HTTPHeaders = ["Authentication": apiKey]
        
        AF.request("\(BASE_URL)/api/aliases/\(id)", method: .get, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).response { response in
            
            guard let statusCode = response.response?.statusCode else {
                completion(.failure(.unknownResponseStatusCode))
                return
            }
            
            switch statusCode {
            case 200:
                guard let data = response.data else {
                    completion(.failure(.noData))
                    return
                }
                
                do {
                    let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : Any]
                    
                    if let jsonDictionary = jsonDictionary {
                        do {
                            let alias = try Alias(fromDictionary: jsonDictionary)
                            completion(.success(alias))
                        } catch let error as SLError {
                            completion(.failure(error))
                        }
                    }
                    
                } catch {
                    completion(.failure(.failToSerializeJSONData))
                }
                
            case 401: completion(.failure(.invalidApiKey))
            case 500: completion(.failure(.internalServerError))
            case 502: completion(.failure(.badGateway))
            default: completion(.failure(.unknownErrorWithStatusCode(statusCode: statusCode)))
            }
        }
    }
}

// MARK: - Contact
extension SLApiService {
    static func fetchContacts(apiKey: ApiKey, aliasId: Alias.Identifier, page: Int, completion: @escaping (Result<[Contact], SLError>) -> Void) {
        let headers: HTTPHeaders = ["Authentication": apiKey]
        
        AF.request("\(BASE_URL)/api/aliases/\(aliasId)/contacts?page_id=\(page)", method: .get, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).response { response in
            
            guard let statusCode = response.response?.statusCode else {
                completion(.failure(.unknownResponseStatusCode))
                return
            }
            
            switch statusCode {
            case 200:
                guard let data = response.data else {
                    completion(.failure(.noData))
                    return
                }
                
                do {
                    let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : Any]
                    
                    if let contactDictionaries = jsonDictionary?["contacts"] as? [[String : Any]] {
                        var contacts: [Contact] = []
                        try contactDictionaries.forEach { (dictionary) in
                            do {
                                try contacts.append(Contact(fromDictionary: dictionary))
                            } catch let error as SLError {
                                completion(.failure(error))
                                return
                            }
                        }
                        
                        completion(.success(contacts))
                        
                    } else {
                        completion(.failure(.failToSerializeJSONData))
                    }
                    
                } catch {
                    completion(.failure(.failToSerializeJSONData))
                }
                
            case 400: completion(.failure(.badRequest(description: "page_id must be provided in request query.")))
            case 401: completion(.failure(.invalidApiKey))
            case 500: completion(.failure(.internalServerError))
            case 502: completion(.failure(.badGateway))
            default: completion(.failure(.unknownErrorWithStatusCode(statusCode: statusCode)))
            }
        }
    }
    
    static func createContact(apiKey: ApiKey, aliasId: Alias.Identifier, email: String, completion: @escaping (Result<Any?, SLError>) -> Void) {
        let headers: HTTPHeaders = ["Authentication": apiKey]
        let parameters = ["contact" : email]
        
        AF.request("\(BASE_URL)/api/aliases/\(aliasId)/contacts", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers, interceptor: nil).response { response in
            
            guard let statusCode = response.response?.statusCode else {
                completion(.failure(.unknownResponseStatusCode))
                return
            }
            
            switch statusCode {
            case 201: completion(.success(nil))
            case 401: completion(.failure(.invalidApiKey))
            case 409: completion(.failure(.duplicatedContact))
            case 500: completion(.failure(.internalServerError))
            case 502: completion(.failure(.badGateway))
            default: completion(.failure(.unknownErrorWithStatusCode(statusCode: statusCode)))
            }
        }
    }
    
    static func deleteContact(apiKey: ApiKey, id: Contact.Identifier, completion: @escaping (Result<Any?, SLError>) -> Void) {
        let headers: HTTPHeaders = ["Authentication": apiKey]
        
        AF.request("\(BASE_URL)/api/contacts/\(id)", method: .delete, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).response { response in
            
            guard let statusCode = response.response?.statusCode else {
                completion(.failure(.unknownResponseStatusCode))
                return
            }
            
            switch statusCode {
            case 200:
                guard let data = response.data else {
                    completion(.failure(.noData))
                    return
                }
                
                do {
                    let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : Any]
                    
                    if let deleted = jsonDictionary?["deleted"] as? Bool {
                        deleted ? completion(.success(nil)) : completion(.failure(.failToDelete(objectName: "Contact")))
                    } else {
                        completion(.failure(.failToParseObject(objectName: "delete contact")))
                    }
                    
                } catch {
                    completion(.failure(.failToSerializeJSONData))
                }
                
            case 401: completion(.failure(.invalidApiKey))
            case 500: completion(.failure(.internalServerError))
            case 502: completion(.failure(.badGateway))
            default: completion(.failure(.unknownErrorWithStatusCode(statusCode: statusCode)))
            }
        }
    }
}

// MARK: - IAP
extension SLApiService {
    static func processPayment(apiKey: ApiKey, receiptData: String, completion: @escaping (Result<Any?, SLError>) -> Void) {
        let headers: HTTPHeaders = ["Authentication": apiKey]
        let parameters = ["receipt_data": receiptData]
        
        AF.request("\(BASE_URL)/api/apple/process_payment", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers, interceptor: nil).response { response in
            
            guard let statusCode = response.response?.statusCode else {
                completion(.failure(.unknownResponseStatusCode))
                return
            }
            
            switch statusCode {
            case 200: completion(.success(nil))
            case 401: completion(.failure(.invalidApiKey))
            case 500: completion(.failure(.internalServerError))
            case 502: completion(.failure(.badGateway))
            default: completion(.failure(.unknownErrorWithStatusCode(statusCode: statusCode)))
            }
        }
    }
}