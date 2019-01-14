//
//  GaiaKeyHeaderCell.swift
//  Cosmos Client
//
//  Created by Calin Chitu on 13/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi

class GaiaKeyHeaderCell: UITableViewCell {

    @IBOutlet weak var leftLabel: UILabel!
    @IBOutlet weak var leftButton: UIButton!
    
    @IBOutlet weak var rightLabel: UILabel!
    @IBOutlet weak var rightButton: UIButton!
    
    
    @IBAction func rightHeaderTap(_ sender: Any) {
        onForgetPassTap?(section)
    }
    
    @IBAction func leftHeaderTap(_ sender: Any) {
        onMoreOptionsTap?(section)
    }
    
    var onForgetPassTap: ((_ : Int)->())?
    var onMoreOptionsTap: ((_ : Int)->())?

    
    private var section: Int = 0
    
    func updateCell(sectionIndex: Int, key: GaiaKey) {
        section = sectionIndex
        rightLabel.textColor = key.isUnlocked ? UIColor.darkBlue : UIColor.disabledGrey
        leftLabel.textColor = rightLabel.textColor
        rightButton.isEnabled = key.isUnlocked
        leftButton.isEnabled = rightButton.isEnabled
    }

}
