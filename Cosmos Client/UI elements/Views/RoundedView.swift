//
//  RoundedView.swift
//
//  Created by Calin Chitu on 24/04/2018.
//  Copyright © 2018 Cristina Virlan. All rights reserved.
//

import UIKit

@IBDesignable
class RoundedView: UIView {
    var isBordered: Bool?
    
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
                layer.shadowOpacity = 0.1
            }
        }
    }
    
    @IBInspectable open var cornerRadius: CGFloat = 5 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }

    open override func layoutSubviews() {
        
        super.layoutSubviews()
        layer.cornerRadius = cornerRadius
    }
}

