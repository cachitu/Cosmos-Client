//
//  RoundedButton.swift
//
//  Created by Cristina Virlan on 17/04/2018.
//  Copyright © 2018 Cristina Virlan. All rights reserved.
//

import UIKit

@IBDesignable
class RoundedButton: UIButton {
    
    var isBordered: Bool?
    @IBInspectable open var activeColor: UIColor = .defaultBackground {
        didSet {
            backgroundColor = activeColor
        }
    }
    
    @IBInspectable open var border: Bool = false {
        didSet {
            isBordered = border
        }
    }
    
    @IBInspectable open var borderColor: UIColor = UIColor.black {
        didSet {
            if isBordered == true {
                self.layer.borderWidth = 1
                self.layer.borderColor = borderColor.cgColor
                backgroundColor = .clear
            }
        }
    }
    
    @IBInspectable open var shadow: Bool = false {
        didSet {
            if shadow {
                layer.shadowColor = UIColor.black.cgColor
                layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
                layer.masksToBounds = false
                layer.shadowRadius = 3.0
                layer.shadowOpacity = 0.2
            }
        }
    }
    
    open override func layoutSubviews() {
        
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }
    
    open override var isEnabled: Bool {
        
        didSet {
            backgroundColor = border ? .clear : isEnabled ? activeColor : .disabledGrey
        }
    }

}


