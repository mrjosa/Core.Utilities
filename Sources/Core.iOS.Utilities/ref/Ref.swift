//
//  File.swift
//  
//
//  Created by Sandman.Jonas on 28/06/2024.
//

import Foundation

public class Ref<T>
{
    private var _value: T
        
    public init(_ value: T) {
        self._value = value
    }
    
    public var value: T {
        get {
            return _value
        }
        set {
            _value = newValue
        }
    }
}
