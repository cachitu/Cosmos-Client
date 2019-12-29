//
//  GaiaHistoryCell.swift
//  Cosmos Client
//
//  Created by kytzu on 23/02/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi

class GaiaHistoryCell: UITableViewCell {

    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var toLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var hashLabel: UILabel!
    @IBOutlet weak var sentOrReceivedLabel: UILabel!
    @IBOutlet weak var heightLabel: UILabel!
    
    func configure(tx: GaiaTransaction, ownerAddr: String) {
        heightLabel.text = "Height: \(tx.height)"
        fromLabel.text   = tx.sender
        toLabel.text     = tx.recipient
        let symbol = tx.isSender ? "▶ " : "◀ "
        amountLabel.text = symbol + tx.amount
        hashLabel.text   = tx.hash
        sentOrReceivedLabel.text = tx.gas + " gas"
        amountLabel.textColor = tx.isSender ? UIColor.pendingYellow : UIColor.progressGreen
        //fromLabel.textColor = ownerAddr == tx.sender   ? UIColor.darkText : UIColor.textGrey
        //toLabel.textColor   = ownerAddr == tx.recipient ? UIColor.darkText : UIColor.textGrey
    }
}
