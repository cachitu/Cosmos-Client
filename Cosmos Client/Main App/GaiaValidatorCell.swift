//
//  GaiaValidatorCell.swift
//  Cosmos Client
//
//  Created by Calin Chitu on 23/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi

class GaiaValidatorCell: UITableViewCell {

    @IBOutlet weak var monikerLabel: UILabel!
    @IBOutlet weak var operatorLabel: UILabel!
    @IBOutlet weak var jailedLabel: UILabel!
    @IBOutlet weak var sharesLabel: UILabel!
    @IBOutlet weak var delegationsLabel: UILabel!
    @IBOutlet weak var rateLabel: UILabel!
    
    func configure(validator: GaiaValidator, index: Int) {
        
        let dShares = Double(validator.shares) ?? 0
        let dTokens = Double(validator.tokens) ?? 0
        let dRate = Double(validator.rate) ?? 0
        
        monikerLabel.text = "\(index): " + validator.moniker
        operatorLabel.text = validator.validator
        jailedLabel.isHidden = !validator.jailed
        sharesLabel.text = "\(dShares) Shares"
        delegationsLabel.text = "\(dTokens) Tokens"
        rateLabel.text = "\(dRate) rate"
    }
    
}
