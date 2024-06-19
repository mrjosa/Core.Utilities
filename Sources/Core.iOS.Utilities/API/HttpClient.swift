//
//  APIManager.swift
//
//  Simple API manager to complement webviews

//  Created by Sandman.Jonas on 07/02/2024.
//

import Foundation

public class HttpClient : NSObject, URLSessionTaskDelegate
{
    public static let shared = HttpClient()
    
    // if you want to override..
    private var onChallengeEvent: ((URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?))?
    public  var willRedirectEvent: ((URLResponse, URLRequest) -> (URLRequest))?
    public  var defaultChallengeEvent: ((URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?))?
    public  var onDataReceived: ((String?) -> Void)?
    
    public var authenticationScheme = "Bearer"
    
    public var timeout : TimeInterval = 60
    public var cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData
    public var dispatchOnMainQueue = true
    
    public var authenticationToken : (() -> String?)?
    
    public var onAuthenticationRequiredEvent: ((Data?, URLResponse) -> Void)?
    
    private var cache : [(url : URL, data: Data)] = []
    
    public var cacheSize : Int = 1
    
    public override init()
    {
        super.init()
    }
    
    // MARK: get with Data
    public func get(_ url : URL, 
                    httpHeaders : [String: String?] = [:],
                    completion : @escaping (Data?, Error?, URLResponse?) -> Void)
    {
        return execute(url: url,
                       method: HttpMethod.get,
                       body: nil,
                       useCache: false,
                       timeout: nil,
                       httpHeaders: httpHeaders,
                       completion: completion,
                       onChallenge: nil)
    }
    
    public func get(_ url : URL,
                    useCache: Bool,
                    httpHeaders : [String: String?] = [:],
                    completion : @escaping (Data?, Error?, URLResponse?) -> Void)
    {
        return execute(url: url,
                       method: HttpMethod.get,
                       body: nil,
                       useCache: useCache,
                       timeout: nil,
                       httpHeaders: httpHeaders,
                       completion: completion,
                       onChallenge: nil)
    }
    
    public func get(_ url : URL, 
                    completion : @escaping (Data?, Error?, URLResponse?) -> Void)
    {
        return execute(url: url,
                       method: HttpMethod.get,
                       body: nil,
                       useCache: false,
                       timeout: nil,
                       httpHeaders: [:],
                       completion: completion,
                       onChallenge: nil)
    }
    
    // MARK: post with Data
    public func post(_ url: URL,
                     body: Any?,
                     completion: @escaping (Data?, Error?, URLResponse?) -> Void) {
        
        execute(url: url,
                method: HttpMethod.post,
                body: body,
                useCache: false,
                timeout: nil,
                httpHeaders: [:],
                completion: { (data, error, response) in
                    
                    completion(data, error, response)
                },
                onChallenge: nil)
    }
    
    public func post(_ url: URL,
                     body: Any?,
                     httpHeaders : [String: String?],
                     completion: @escaping (Data?, Error?, URLResponse?) -> Void) {
        
        execute(url: url,
                method: HttpMethod.post,
                body: body,
                useCache: false,
                timeout: nil,
                httpHeaders: [:],
                completion: { (data, error, response) in
                    
                    completion(data, error, response)
                },
                onChallenge: nil)
    }
    
    private func execute(url : URL,
                         method : String,
                         body: Any?,
                         useCache: Bool,
                         timeout: TimeInterval?,
                         httpHeaders : [String: String?] = [:],
                         completion : @escaping (Data?, Error?, URLResponse?) -> Void,
                         onChallenge: ((URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?))?)
    {
        if useCache == true &&
            method == HttpMethod.get,
           let kv = cache.first(where: { (cacheUrl: URL, data: Any) in
               return url == cacheUrl
           }) {
            self.dispatchOnCorrectThread {
                completion(kv.data, nil, nil)
            }
        }
        else {
            
            self.onChallengeEvent = onChallengeEvent ?? defaultChallengeEvent
            
            let request = NSMutableURLRequest(url: url);
            
            let session = URLSession.shared
            session.configuration.requestCachePolicy = self.cachePolicy
            session.configuration.timeoutIntervalForRequest = timeout ?? self.timeout
            request.httpMethod = method
            // TODO: support urlencoded?
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if let token = self.authenticationToken?() {
                request.setValue("\(authenticationScheme) \(token)", forHTTPHeaderField: "Authorization")
            }
            
            if let body = body {
                request.httpBody = encodeBody(body: body)
            }
            
            for (field, value) in httpHeaders {
                
                if value?.isEmpty ?? true == false {
                    request.setValue(value, forHTTPHeaderField: field)
                }
            }
            
            let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error -> Void in
                
                if let error = error as? URLError {
                    
                    let nsError = NSError(domain: NSURLErrorDomain, code: error.errorCode)
                    
                    self.dispatchOnCorrectThread {
                        completion(nil, error, response)
                    }
                    
                }
                else {
                    
                    if let response = response as? HTTPURLResponse {
                        
                        if self.onAuthenticationRequiredEvent != nil &&
                            response.statusCode == 401 {
                            self.dispatchOnCorrectThread {
                                self.onAuthenticationRequiredEvent?(data, response)
                            }
                        }
                        else {
                            self.dispatchOnCorrectThread {
                                completion(data, nil, response)
                            }
                        }
                    }
                    else {
                        self.dispatchOnCorrectThread {
                            completion(data, nil, response)
                        }
                    }
                }
            })
            
            if #available (iOS 17, *) {
                task.delegate = self
            }
            
            task.resume()
        }
    }
    
    // MARK: URLSessionTaskDelegate
    public func urlSession(_ session: URLSession,
                didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        if let result = self.onChallengeEvent?(challenge) {
            self.dispatchOnCorrectThread {
                completionHandler(result.0, result.1)
            }
            
        }
        else {
            self.dispatchOnCorrectThread {
                completionHandler(.performDefaultHandling, nil)
            }
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) async -> URLRequest? {
        
        return self.willRedirectEvent?(response, request)
    }
    
    private func encodeBody(body : Any?) -> Data?
    {
        if let body = body as? [String : Any?] {
            
            let body = body.compactMapValues { value -> Any? in
                
                if let value = value as? String {
                    return value
                }
                else if let value = value as? Int {
                    return value
                }
                else if let value = value as? Double {
                    return value
                }
                
                return nil
            }
            
            let data = try! JSONSerialization.data(withJSONObject: body)
            return data
        }
        else if let body = body as? Encodable {
            
            let encoder = JSONEncoder()
            return try? encoder.encode(body)
        }
        
        return nil
    }
    
    private func dispatchOnCorrectThread(_ block : @escaping (() -> Void))
    {
        if self.dispatchOnMainQueue &&
            Thread.isMainThread == false {
            DispatchQueue.main.async {
                block()
            }
        }
        else {
            block()
        }
    }
}
