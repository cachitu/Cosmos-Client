//
//  GaiaNodeHeaderCell.swift
//  Cosmos Client
//
//  Created by Calin Chitu on 12/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit

class GaiaNodeHeaderCell: UITableViewCell {

    @IBOutlet weak var leftlabel: UILabel!
    
    @IBAction func headerTap(_ sender: Any) {
        onTap?(section)
    }
    
    var onTap: ((_ : Int)->())?
    private var section: Int = 0
    
    func updateCell(sectionIndex: Int, name: String) {
        section = sectionIndex
        leftlabel.text = name
    }
    
}
