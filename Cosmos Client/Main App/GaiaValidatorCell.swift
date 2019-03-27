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
    
    func configure(account: GaiaAccount?, validator: GaiaValidator, index: Int) {
        
        let dShares = Double(validator.shares) ?? 0
        let dTokens = Double(validator.tokens) ?? 0
        let dRate = Double(validator.rate) ?? 0
        
        monikerLabel.text = "\(index): " + validator.moniker
        operatorLabel.text = validator.validator
        jailedLabel.isHidden = !validator.jailed
        let finalShares = "\(dShares)".split(separator: ".").first ?? "0"
        sharesLabel.text = "\(finalShares) Shares"
        let finalTokens = "\(dTokens)".split(separator: ".").first ?? "0"
        delegationsLabel.text = "\(finalTokens) Tokens"
        rateLabel.text = "\(dRate) rate"
        
        monikerLabel.textColor = .darktext
        if account?.gaiaKey.validator == validator.validator {
            monikerLabel.textColor = .darkBlue
        }
    }
    
}
