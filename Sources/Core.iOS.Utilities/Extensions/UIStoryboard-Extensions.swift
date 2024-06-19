//
//  File.swift
//  
//
//  Created by Sandman.Jonas on 02/04/2024.
//

import Foundation
import UIKit

extension UIStoryboard {
    
    public static func loadStoryboard(_ name : String, forLanguage languageCode: String) -> UIStoryboard
    {
        var localizedStoryboardName = name
        
        // Append language suffix if not the default language
        if languageCode != "en" {
            localizedStoryboardName += "-\(languageCode)"
        }
        
        return UIStoryboard(name: localizedStoryboardName, bundle: nil)
    }
}
