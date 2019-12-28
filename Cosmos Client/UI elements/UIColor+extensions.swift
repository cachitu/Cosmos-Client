//
//  UIColor+extensions.swift
//
//  Created by Cristina Virlan on 17/04/2018.
//  Copyright © 2018 Cristina Virlan. All rights reserved.
//

import UIKit

// MARK:- Custom colors
public extension UIColor {
    
    static var darkGrayText: UIColor {
        return UIColor(named: "DarkGrayText") ?? UIColor(red: 42.0 / 255.0, green: 42.0 / 255.0, blue: 42.0 / 255.0, alpha: 1.0)
    }
       
    static var ligtherGrayText: UIColor {
        return UIColor(named: "LigtherGrayText") ?? UIColor(red: 153.0 / 255.0, green: 153.0 / 255.0, blue: 153.0 / 255.0, alpha: 1.0)
    }

    static var ligthText: UIColor {
        return UIColor(named: "LigthText") ?? UIColor(red: 255 / 255.0, green: 255 / 255.0, blue: 255 / 255.0, alpha: 1.0)
    }

    static var tabBarGray: UIColor {
        return UIColor(red: 146.0 / 255.0, green: 146.0 / 255.0, blue: 146.0 / 255.0, alpha: 1.0)
    }

    static var darkRed: UIColor {
        return UIColor(named: "DarkRed") ?? UIColor(red: 207.0 / 255.0, green: 14.0 / 255.0, blue: 14.0 / 255.0, alpha: 1.0)
    }
    
    static var progressGreen: UIColor {
        return UIColor(named: "ProgressGreen") ?? UIColor(red: 0.0 / 255.0, green: 193.0 / 255.0, blue: 64.0 / 255.0, alpha: 1.0)
    }
    
    static var progressGray: UIColor {
        return UIColor(red: 229.0 / 255.0, green: 229.0 / 255.0, blue: 229.0 / 255.0, alpha: 1.0)
    }
    
    @nonobjc class var silver: UIColor {
        return UIColor(named: "Silver") ?? UIColor(red: 206.0 / 255.0, green: 212.0 / 255.0, blue: 218.0 / 255.0, alpha: 1.0)
    }
    
    @nonobjc class var silverAlpha: UIColor {
        return UIColor(red: 206.0 / 255.0, green: 212.0 / 255.0, blue: 218.0 / 255.0, alpha: 0.31)
    }
    
    @nonobjc class var lightBlue: UIColor {
        return UIColor(red: 42.0 / 255.0, green: 172.0 / 255.0, blue: 224.0 / 255.0, alpha: 1.0)
    }
    
    @nonobjc class var cellBackgroundColor: UIColor {
        return UIColor(named: "CellBackgroundColor") ?? .white
    }

    @nonobjc class var defaultBackground: UIColor {
        return UIColor(named: "DefaultBackground") ?? UIColor(red: 44.0 / 255.0, green: 77.0 / 255.0, blue: 178.0 / 255.0, alpha: 1.0)
    }

    @nonobjc class var darkBlue: UIColor {
        return UIColor(red: 44.0 / 255.0, green: 72 / 255.0, blue: 167 / 178.0, alpha: 1.0)
    }
    
    @nonobjc class var pendingYellow: UIColor {
        return UIColor(named: "Pending") ?? UIColor(red: 193.0 / 255.0, green: 142 / 255.0, blue: 0 / 255.0, alpha: 1.0)
    }
    
    @nonobjc class var warmGrey: UIColor {
        return UIColor(white: 112.0 / 255.0, alpha: 1.0)
    }
    
    @nonobjc class var disabledGrey: UIColor {
        return UIColor(white: 161.0 / 255.0, alpha: 1.0)
    }

    @nonobjc class var textGrey: UIColor {
        return UIColor(white: 151.0 / 255.0, alpha: 1.0)
    }

}
