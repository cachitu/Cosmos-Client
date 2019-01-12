//
//  CustomTabBarItem.swift
//  IPSX
//
//  Created by Calin Chitu on 13/12/2018.
//  Copyright © 2018 Cristina Virlan. All rights reserved.
//

import UIKit

class CustomTabBarItem: UIView {
    
    var onTap:( () -> () )?
    var selected = false {
        didSet {
            image?.tintColor      = selected ? .lightBlue : .tabBarGray
            titleLabel?.textColor = selected ? .lightBlue : .tabBarGray
        }
    }
    
    @IBOutlet weak var image: UIImageView?
    @IBOutlet weak var titleLabel: UILabel?
    
    @IBAction func tapAction(_ sender: UIButton) {
         onTap?()
    }
}
