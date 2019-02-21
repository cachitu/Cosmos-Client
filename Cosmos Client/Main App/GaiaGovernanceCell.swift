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
    @IBOutlet weak var abstainLabel: UILabel!
    @IBOutlet weak var noVetoLabel: UILabel!
    @IBOutlet weak var totalDeposited: UILabel!
    
    func configure(proposal: GaiaProposal) {
        
        let dYes = Double(proposal.yes) ?? 0
        let dNo  = Double(proposal.no) ?? 0
        let dAbs = Double(proposal.abstain) ?? 0
        let dNoV = Double(proposal.noWithVeto) ?? 0

        typeLabel.text = proposal.type
        proposalTitleLabel.text = proposal.title
        proposalDescriptionLabel.text = proposal.description
        switch proposal.status {
        case "Passed"  : statusLabel.textColor = UIColor.progressGreen
        case "Rejected": statusLabel.textColor = UIColor.darkRed
        default        : statusLabel.textColor = UIColor.pendingYellow
        }
        statusLabel.text = proposal.status
        let finalYes = "\(dYes)".split(separator: ".").first ?? "0"
        let finalNo  = "\(dNo)".split(separator: ".").first ?? "0"
        let finalAbs = "\(dAbs)".split(separator: ".").first ?? "0"
        let finalNoV = "\(dNoV)".split(separator: ".").first ?? "0"
        yesLabel.text     = finalYes + " - Yes"
        noLabel.text      = finalNo + " - No"
        abstainLabel.text = finalAbs + " - Abstain"
        noVetoLabel.text  = finalNoV + " - No (Veto)"
        totalDeposited.text = "Dep: \(proposal.totalDepopsit)"
    }
}
