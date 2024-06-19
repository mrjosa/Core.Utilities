//
//  File.swift
//  
//
//  Created by Sandman.Jonas on 18/04/2024.
//

import Foundation

public class HttpClientFactory
{
    static func getInstance() -> HttpClient
    {
        return HttpClient()
    }
}
