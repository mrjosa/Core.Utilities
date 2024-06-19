//
//  File.swift
//
//
//  Created by Sandman.Jonas on 02/04/2024.
//

import Foundation
import UIKit

public class NumberPad : UILabel, UIKeyInput
{
    public var hasText: Bool {
        return currentLength > 0
    }
    
    public var keyLength = 4
    @IBOutlet public var delegate : NumberPadDelegate!
    
    public override var canBecomeFirstResponder: Bool { return true }
    public override var canResignFirstResponder: Bool { return false }
    
    private var inputCode = ""
    {
        didSet
        {
            let combinedString = self.inputCode + stride(from: self.inputCode.count, to: keyLength, by: 1).map { _ in "-" }.joined()
            
            self.text = combinedString.map{ String($0) }.joined(separator: " ")
        }
    }
    private var currentLength : Int {
        return self.inputCode.count
    }
    
    public var keyboardType: UIKeyboardType { get { .numberPad } set { } }
    
    public var textContentType: UITextContentType {
        
        get {
            return .oneTimeCode
        }
        set {
            // This is a no-op because we want to enforce a specific content type
        }
    }
    
    public func clear()
    {
        self.inputCode = ""
    }
    
    // MARK: UIKeyInput
    public func insertText(_ text: String)
    {
        if self.currentLength < self.keyLength &&
           self.isEnabled {
           self.inputCode = self.inputCode + text
            
            if currentLength == keyLength {
                
                self.delegate.numberPad(self, didFinishWithCode: self.inputCode)
            }
        }
    }
    
    public func deleteBackward()
    {
        if self.currentLength > 0 &&
           self.isEnabled {
           self.inputCode = String(self.inputCode.dropLast())
        }
    }
}

@objc public protocol NumberPadDelegate
{
    func numberPad(_ numberPad: NumberPad, didFinishWithCode code: String)
}
