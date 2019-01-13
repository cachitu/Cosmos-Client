//
//  GaiaKeyHeaderCell.swift
//  Cosmos Client
//
//  Created by Calin Chitu on 13/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit

class GaiaKeyHeaderCell: UITableViewCell {

    @IBAction func rightHeaderTap(_ sender: Any) {
        onForgetPassTap?(section)
    }
    
    @IBAction func leftHeaderTap(_ sender: Any) {
        onDeleteTap?(section)
    }
    
    var onForgetPassTap: ((_ : Int)->())?
    var onDeleteTap: ((_ : Int)->())?

    
    private var section: Int = 0
    
    func updateCell(sectionIndex: Int, name: String) {
        section = sectionIndex
    }

}
