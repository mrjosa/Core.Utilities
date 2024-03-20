//
//  APIManager.swift
//
//  Simple API manager to complement webviews

//  Created by Sandman.Jonas on 07/02/2024.
//

import Foundation

public class APIManager : NSObject, URLSessionTaskDelegate
{
    public static let shared = APIManager()
    
    // if you want to override..
    private var onChallengeEvent: ((URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?))?
    public  var willRedirectEvent: ((URLResponse, URLRequest) -> (URLRequest))?
    public  var defaultChallengeEvent: ((URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?))?
    public  var onDownloadEvent: ((String?) -> Void)?
    
    public var timeout : TimeInterval = 60
    public var cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData
    
    
    private var cache : [(url : URL, data: Any)] = []
    
    public var cacheSize : Int = 1
    
    override init()
    {
        super.init()
    }
    
    public func get<T: Decodable>(_ url : URL,
                           useCache: Bool,
                           httpHeaders : [String: String?] = [:],
                           completion : @escaping (Result<T, Error>, URLResponse?) -> Void)
    {
        execute(url: url,
                method: HttpMethod.get,
                body: nil,
                useCache: useCache,
                timeout: nil,
                httpHeaders: httpHeaders,
                completion: completion,
                onChallenge: nil)
    }
    
    public func get<T: Decodable>(_ url : URL,
                           useCache: Bool,
                           timeout: TimeInterval?,
                           httpHeaders : [String: String?] = [:],
                           completion : @escaping (Result<T, Error>, URLResponse?) -> Void)
    {
        execute(url: url,
                method: HttpMethod.get,
                body: nil,
                useCache: useCache,
                timeout: timeout,
                httpHeaders: httpHeaders,
                completion: completion,
                onChallenge: nil)
    }
    
    public func post<T: Decodable>(url : URL,
                                   body: [String: Any?],
                                   useCache: Bool,
                                   httpHeaders : [String: String?] = [:],
                                   completion : @escaping (Result<T, Error>, URLResponse?) -> Void)
    {
        execute(url: url,
                method: HttpMethod.post,
                body: body,
                useCache: useCache,
                timeout: nil,
                httpHeaders: httpHeaders,
                completion: completion,
                onChallenge: nil)
    }
    
    func execute<T : Decodable>(url : URL,
                                method : String,
                                body: [String: Any?]?,
                                useCache: Bool,
                                timeout: TimeInterval?,
                                httpHeaders : [String: String?] = [:],
                                completion : @escaping (Result<T, Error>, URLResponse?) -> Void,
                                onChallenge: ((URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?))?)
    {
        if useCache == true {
            
            if let kv = cache.first(where: { (cacheUrl: URL, data: Any) in
                return url == cacheUrl
            }) {
                if let data = kv.data as? T {
                    completion(.success(data), nil)
                }
            }
        }
        
        self.onChallengeEvent = onChallengeEvent ?? defaultChallengeEvent
        
        let request = NSMutableURLRequest(url: url);
        
        
        let session = URLSession.shared
        session.configuration.requestCachePolicy = self.cachePolicy
        session.configuration.timeoutIntervalForRequest = timeout ?? self.timeout
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        for (field, value) in httpHeaders {
            
            if value?.isEmpty ?? true == false {
                request.setValue(value, forHTTPHeaderField: field)
            }
        }
        
        if let body = body {
            
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
            request.httpBody = data
        }
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error -> Void in
            
            do {
                if let error = error as? URLError {
                    
                    let nsError = NSError(domain: NSURLErrorDomain, code: error.errorCode)
                    
                    completion(.failure(nsError), response)
                }
                else {
                    
                    if let data = data {
                        
                        self.onDownloadEvent?(String(data: data, encoding: .utf8))
                        
                        //let a = String(data: data, encoding: .utf8)
                        
                        let decoder = JSONDecoder()
                        
                        let json = try decoder.decode(T.self, from: data)
                        
                        if let url = request.url {
                            if self.cache.count >= self.cacheSize {
                                self.cache.removeFirst()
                            }
                            
                            self.cache.append((url: url, data: json))
                        }
                        
                        completion(.success(json), response)
                    }
                }
            }
            catch let error as NSError {
                
                completion(.failure(error), response)
            }
        })
        
        if #available (iOS 17, *) {
            task.delegate = self
        }
        
        task.resume()
    }
    
    // MARK: URLSessionTaskDelegate
    public func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        if let result = self.onChallengeEvent?(challenge) {
            completionHandler(result.0, result.1)
        }
        else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) async -> URLRequest? {
        
        return self.willRedirectEvent?(response, request)
    }
}


