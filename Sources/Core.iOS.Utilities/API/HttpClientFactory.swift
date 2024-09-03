//
//  File.swift
//  
//
//  Created by Sandman.Jonas on 18/04/2024.
//

import Foundation

public class HttpClientFactory
{
    public static func getInstance(_ dispatchOnMainThread : Bool = true) -> HttpClient
    {
        let client = HttpClient()
        
        client.dispatchOnMainQueue = dispatchOnMainThread
        
        return client
    }
}
