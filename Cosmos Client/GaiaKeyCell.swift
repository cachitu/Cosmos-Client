//
//  GaiaKeyCell.swift
//  Cosmos Client
//
//  Created by Calin Chitu on 13/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi

class GaiaKeyCell: UITableViewCell {

    @IBOutlet weak var leftImageView: UIImageView!
    @IBOutlet weak var leftLabel: UILabel!
    @IBOutlet weak var leftSubLabel: UILabel!
    @IBOutlet weak var rightLabel: UILabel!
    
    func configure(key: GaiaKey) {
        leftLabel.text = key.name
        leftSubLabel.text = key.address
        rightLabel.text = key.type
        let imageName = key.isUnlocked ? "approved" : "locked"
        if let image = UIImage(named: imageName) {
            leftImageView.image = image
        }
    }
}
