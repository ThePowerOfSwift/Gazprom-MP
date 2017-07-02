//
//  HTTPClient.swift
//  Gazprom-Perm
//
//  Created by Александр Васильев on 05/06/2017.
//  Copyright © 2017 AVasilyev. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireObjectMapper

let baseUrl = "http://ppu.**********.ru/"

let userDef = UserDefaults.standard

class HttpClient: NSObject {
    static let shared = HttpClient()
    private var sessionManager = Alamofire.SessionManager.default
    
    override init() {
        super.init()
        configManager()
    }
    
    func configManager() {
        
        var defaultHeaders = Alamofire.SessionManager.defaultHTTPHeaders
        
        if let token = JWT().token {
            // token always in header
            defaultHeaders["Authorization"] = "Bearer \(token)"
        }
        
        let configuration = URLSessionConfiguration.default
        
        configuration.httpAdditionalHeaders = defaultHeaders
        
        sessionManager = Alamofire.SessionManager(configuration: configuration)
    }
    
    // MARK: - Auth. Send phone number and authorization code
    
    func authorisation(auth:Auth, complection:@escaping(JWT?) -> Void) {
        print(auth.toJSON())
        sessionManager.request(baseUrl + "client_token", method: .post, parameters: auth.toJSON(), encoding: JSONEncoding.default).responseObject{ (response:DataResponse<JWT>) in
            print(response.response as Any)
            self.configManager()
            complection(response.result.value)
        }
    }
    
    // MARK: - Registration.
    
    // Send only phone number to the remote server to receive SMS-code
    // ".validate() - provides checking for code in between 200-300
    func registration(registr: Registration, completion:@escaping(Int?) -> Void) {
        print(registr.toJSON()) // print what was sent
        sessionManager.request(baseUrl + "api/try_login.json", method: .post, parameters: registr.toJSON(), encoding: JSONEncoding.default).validate().response { (response) in
            completion(response.response?.statusCode) // passing status code for checking in appropriate view controller
            }.responseString { (responseString) in print(responseString)
        }
    }
    
    // MARK: - Accounts (for registered users)
    
    func accounts(complection:@escaping([Account]?) -> Void) {
        sessionManager.request(baseUrl + "ebstoreservice/api/personal-accounts", method: .get, encoding: JSONEncoding.default).responseArray{
            (response:DataResponse<[Account]>) in
            complection(response.result.value)
        }
    }
    
    // MARK: - Delete Account
    
    func deleteAccount(withID ident: Int64, completion:@escaping(Int?) -> Void) {
        sessionManager.request(baseUrl + "ebstoreservice/api/personal-accounts/\(ident)", method: .delete, encoding: JSONEncoding.default).validate().response {
            (response) in
            completion(response.response?.statusCode) // passing status code for checking in appropriate view controller
            }.responseString { (responseString) in print(responseString)
        }
    }
    
    // MARK: - Add Account
    
    func addAccount(registr: AddAccount, completion:@escaping(Int?) -> Void) {
        print(registr.toJSON()) // print what was sent
        sessionManager.request(baseUrl + "ebstoreservice/api/personal-accounts", method: .post, parameters: registr.toJSON(), encoding: JSONEncoding.default).validate().response { (response) in
            completion(response.response?.statusCode) // passing status code for checking in appropriate view controller
            }.responseString { (responseString) in print(responseString)
        }
    }
    
    // MARK: - Branches (available for unregistered users)
    
    func branches(complection:@escaping([Branch]?) -> Void) {
        sessionManager.request(baseUrl + "shops.json", method: .get, encoding: JSONEncoding.default).responseArray{
            (response:DataResponse<[Branch]>) in
            complection(response.result.value)
        }
    }
    
    // MARK: - Services (available for unregistered users)
    
    func serviceTypes(complection:@escaping([ServiceType]?) -> Void) {
        sessionManager.request(baseUrl + "product_types.json", method: .get, encoding: JSONEncoding.default).responseArray{ (response:DataResponse<[ServiceType]>) in
            complection(response.result.value)
        }
    }
    
    func services(complection:@escaping([Service]?) -> Void) {
        sessionManager.request(baseUrl + "catalogs.json", method: .get, encoding: JSONEncoding.default).responseArray{
            (response:DataResponse<[Service]>) in
            complection(response.result.value)
        }
    }
    
    // MARK: - Make Order
    
    func order(parameters: [String : Any], completion:@escaping(Int?) -> Void) {
        sessionManager.request(baseUrl + "api/mobile_order.json", method: .post, parameters: parameters, encoding: JSONEncoding.default).response{ (response) in
            completion(response.response?.statusCode) // passing status code for checking in appropriate view controller
        }
    }
    
    // MARK: - Fetch User Orders
    
    func userOrders(complection:@escaping([Order]?) -> Void) {
        sessionManager.request(baseUrl + "orders/my.json", method: .get, encoding: JSONEncoding.default).responseArray{
            (response:DataResponse<[Order]>) in
            complection(response.result.value)
        }
    }
    
    // MARK: - Messages
    
    // List of messages for authorized user.
    func messages(complection:@escaping([Message]?) -> Void) {
        sessionManager.request(baseUrl + "api/messages.json", method: .get, encoding: JSONEncoding.default).responseArray{
            (response:DataResponse<[Message]>) in
            complection(response.result.value)
        }
    }
    
    // MARK: - Devices
    
    // list of devices according to account. For authorized user.
    func devices(withID ident: Int64, complection:@escaping([Device]?) -> Void) {
        sessionManager.request(baseUrl + "ebstoreservice/api/personal-accounts/\(ident)/energy-instruments", method: .get, encoding: JSONEncoding.default).responseArray{
            (response:DataResponse<[Device]>) in
            complection(response.result.value)
        }
    }
    
    // MARK: - Send Device Value
    
    func passDeviceValue(parameters: DeviceValue, completion:@escaping(Int?) -> Void) {
        sessionManager.request(baseUrl + "ebstoreservice/api/instruments-responses", method: .post, parameters: parameters.toJSON(), encoding: JSONEncoding.default).validate().response{ (response) in
            completion(response.response?.statusCode) // passing status code for checking in appropriate view controller
            }.responseString { (responseString) in print(responseString)
        }
    }
    
    // MARK: - UserInfo
    
    // information about registered user - phone number and id
    func userInfo(complection:@escaping(User?) -> Void) {
        sessionManager.request(baseUrl + "api/client_info.json", method: .get, encoding: JSONEncoding.default).responseObject{
            (response:DataResponse<User>) in
            complection(response.result.value)
        }
    }
}

// MARK: - Download images

extension UIImageView {
    func downloadedFrom(url: URL, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() { () -> Void in
                self.image = image
                }
            }.resume()
    }
    func downloadedFrom(link: String, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        guard let url = URL(string: baseUrl + link) else { return }
        downloadedFrom(url: url, contentMode: mode)
    }
}
