//
//  File.swift
//  
//
//  Created by Sandman.Jonas on 03/06/2024.
//

import Foundation
import QuartzCore
import UIKit

public class ImageAnimator
{
    private var currentIndex : Int = 0
    private var displayLink: CADisplayLink?
    
    public var animationComplete : (() -> ())?
    
    public var imageView : UIImageView!
    
    public var animatedImages : [UIImage]? {
        didSet {
            guard let duration = animationDuration, (animatedImages?.isEmpty ?? false) else {
                self.animationDuration = 1/animatedImages!.count
                
                return
            }
            
            guard let images = animatedImages else {
                stopAnimating()
                
                return
            }
        }
    }
    
    public var animationDuration : Int?
    public var delay : DispatchTimeInterval = .seconds(0)
    public var repeatCount : Int = 1
    
    public init()
    {
    }
    
    public convenience init(images : [UIImage])
    {
        self.init()
        self.animatedImages = images
        
    }
    
    public func startAnimating()
    {
        stopAnimating()
        
        displayLink = CADisplayLink(target: self, selector: #selector(updateImage))
        displayLink?.preferredFramesPerSecond = self.animationDuration ?? 30
        
        self.updateImage()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + self.delay) {
            self.displayLink?.add(to: .main, forMode: .default)
        }
    }
    
    @objc private func updateImage()
    {
        guard let images = animatedImages, !images.isEmpty else {
            stopAnimating()
            return
        }
               
        imageView.image = images[currentIndex]
        currentIndex = (currentIndex + 1) % images.count
        
        if currentIndex == images.count - 1 {
            stopAnimating()
            
            animationComplete?()
        }
    }
    
    public func stopAnimating()
    {
        displayLink?.remove(from: .main, forMode: .default)
    }
}
