//
//  File.swift
//  
//
//  Created by Sandman.Jonas on 27/03/2024.
//

import Foundation

extension NSMutableAttributedString {
    
    public convenience init(_ strings : [NSAttributedString]) {
        self.init()
        
        for str in strings {
            self.append(str)
        }
    }
}
