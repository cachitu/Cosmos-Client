//
//  CustomTabBar.swift
//
//  Created by Calin Chitu on 13/12/2018.
//  Copyright © 2018 Cristina Virlan. All rights reserved.
//

import UIKit

class CustomTabBar: UIView {

    @IBOutlet weak var item1: CustomTabBarItem?
    @IBOutlet weak var item2: CustomTabBarItem?
    @IBOutlet weak var item3: CustomTabBarItem?
    @IBOutlet weak var item4: CustomTabBarItem?
    
    func selectIndex(_ index: Int) {
        
        item1?.selected = index == 0 ? true : false
        item2?.selected = index == 1 ? true : false
        item3?.selected = index == 2 ? true : false
        item4?.selected = index == 3 ? true : false
    }
    
    var onTap:( (Int) -> () )?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        item1?.selected = false
        item1?.onTap = {
            self.onTap?(0)
        }
        item2?.onTap = {
            self.onTap?(1)
        }
        item3?.onTap = {
            self.onTap?(2)
        }
        item4?.onTap = {
            self.onTap?(3)
        }
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        item1?.selected = false
        item2?.selected = false
        item3?.selected = false
        item4?.selected = false
    }
}
