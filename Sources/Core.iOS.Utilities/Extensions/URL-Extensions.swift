//
//  File.swift
//  
//
//  Created by Sandman.Jonas on 27/06/2024.
//

import Foundation

extension URL
{
    public func isRelativeURL() -> Bool {
        
        return self.scheme == nil && self.host == nil
    }
}
