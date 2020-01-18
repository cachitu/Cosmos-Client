//
//  GaiaWalletCell.swift
//  Syncnode
//
//  Created by Calin Chitu on 18/01/2020.
//  Copyright © 2020 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi

class GaiaWalletCell: UITableViewCell {
    
    @IBOutlet weak var aliasLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    func configure(address: GaiaAddressBookItem) {
        aliasLabel.text = address.name
        addressLabel.text = address.address
    }
}
