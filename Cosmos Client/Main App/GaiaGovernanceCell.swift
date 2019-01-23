//
//  GaiaGovernanceCell.swift
//  Cosmos Client
//
//  Created by Calin Chitu on 23/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi

class GaiaGovernanceCell: UITableViewCell {

    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var proposalTitleLabel: UILabel!
    @IBOutlet weak var proposalDescriptionLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var yesLabel: UILabel!
    @IBOutlet weak var noLabel: UILabel!
    
    func configure(proposal: GaiaProposal) {
        
        let dYes = Double(proposal.yes) ?? 0
        let dNo  = Double(proposal.no) ?? 0

        typeLabel.text = proposal.type
        proposalTitleLabel.text = proposal.title
        proposalDescriptionLabel.text = proposal.description
        statusLabel.text = proposal.status
        yesLabel.text = "Yes: \(dYes)"
        noLabel.text  = " No: \(dNo)"
    }
}
