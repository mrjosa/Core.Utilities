//
//  File.swift
//  
//
//  Created by Sandman.Jonas on 20/03/2024.
//

import Foundation
import CryptoKit

public extension String {
   
    func base64encode() -> String {
        
        let inputData = Data(self.utf8)
            
        return inputData.base64EncodedString()
    }
    
    //Allow closed integer range subscripting like `string[0...n]`
    // https://softwareengineering.stackexchange.com/questions/362103/why-doesnt-swift-allow-int-string-subscripting-and-integer-ranges-directly
    subscript(range: ClosedRange<Int>) -> Substring
    {
        let start = self.index(self.startIndex, offsetBy: range.lowerBound)
        let end = self.index(self.startIndex, offsetBy: range.upperBound)
        return self[start...end]
    }
    
    
    func sha256Hash() -> String {
        let inputData = Data(self.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap { String(format: "%02x", $0) }.joined()
        
        return hashString
    }
}
