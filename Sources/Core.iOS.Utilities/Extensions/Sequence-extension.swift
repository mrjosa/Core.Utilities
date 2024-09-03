//
//  File.swift
//  
//
//  Created by Sandman.Jonas on 02/07/2024.
//

import Foundation

extension Sequence where Element: Any
{
    public func ofType<T>(_ type: T.Type) -> [T] {
        return self.compactMap { $0 as? T }
    }
}
