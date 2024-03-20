//
//  KeyStore.swift
//
//  Created by Jonas on 2020-08-18.
//

import Foundation

@objcMembers public class KeyStore : NSObject
{
    @discardableResult public func store(key: String, value : String) -> Bool
    {
        let data = Data(value.utf8)
        
        let query = [
                   kSecClass as String: kSecClassGenericPassword as String,
                   kSecAttrAccount as String: key,
                   kSecValueData as String: data
               ] as [String: Any]

               SecItemDelete(query as CFDictionary)
               
               let result = SecItemAdd(query as CFDictionary, nil)
        
        return result == noErr;
    }
    
    public func remove(key: String) -> Void {
        let query = [
                   kSecClass as String: kSecClassGenericPassword as String,
                   kSecAttrAccount as String: key
               ] as [String: Any]

        SecItemDelete(query as CFDictionary)
    }
    
    public func get(key: String) -> String?
    {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ] as [String: Any]
        
        var dataTypeRef: AnyObject? = nil
        
        SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard let password = dataTypeRef as? Data? else {
            return nil
        }
        
        if let password = password {
            return String(data: password, encoding: String.Encoding.utf8)
        }
        
        return nil
    }
}
