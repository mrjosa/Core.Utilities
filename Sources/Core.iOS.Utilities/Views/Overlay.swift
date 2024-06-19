//
//  File.swift
//  
//
//  Created by Sandman.Jonas on 17/04/2024.
//

import Foundation
import UIKit

public class Overlay : UIView
{
    public var animationDuration : CGFloat = 0.5
    
    public func remove(withAnimation animate : Bool)
    {
        if animate == true {
            UIView.animate(withDuration: animationDuration) {
                
                self.backgroundColor = self.backgroundColor?.withAlphaComponent(0.0)
                
            } completion: { finished in
                
                self.removeFromSuperview()
            }
        }
        else {
            self.removeFromSuperview()
        }
    }
    
    public func show(withColor color : UIColor, animated : Bool)
    {
        show(withColor: color, animated: animated, duration: nil)
    }
    
    public func show(withColor color : UIColor, animated : Bool, duration : CGFloat?)
    {
        if animated == true {
            
            UIView.animate(withDuration: animationDuration) {
                self.backgroundColor = color.withAlphaComponent(0.5)
            }
        }
        else {
            self.backgroundColor = color.withAlphaComponent(0.5)
        }
    }
}
