//
//  File.swift
//  
//
//  Created by Sandman.Jonas on 27/03/2024.
//

import Foundation
import UIKit

extension UIImage {
    
    public func resizeImage(targetSize: CGSize) -> UIImage? {
        let size = self.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }

        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
    
    func tintedImage(withColor color: UIColor) -> UIImage? {
        
        let rect = CGRect(origin: .zero, size: self.size)
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        color.set()
        self.withRenderingMode(.alwaysTemplate).draw(in: rect)
        let tintedImg = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return tintedImg
    }
}
