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
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var yesLabel: UILabel!
    @IBOutlet weak var noLabel: UILabel!
    @IBOutlet weak var abstainLabel: UILabel!
    @IBOutlet weak var noVetoLabel: UILabel!
    @IBOutlet weak var yesValLabel: UILabel!
    @IBOutlet weak var noVallabel: UILabel!
    @IBOutlet weak var abstainValueLabel: UILabel!
    @IBOutlet weak var noVetoValueLabel: UILabel!
    @IBOutlet weak var leftImageVie: UIImageView?
    
    @IBOutlet weak var totalDeposited: UILabel!
    
    func configure(proposal: GaiaProposal, voter: GaiaAccount?, image: UIImage?) {
        
        let dYes = Double(proposal.yes) ?? 0
        let dNo  = Double(proposal.no) ?? 0
        let dAbs = Double(proposal.abstain) ?? 0
        let dNoV = Double(proposal.noWithVeto) ?? 0

        leftImageVie?.image = image
        
        typeLabel.text = proposal.type
        proposalTitleLabel.text = proposal.title
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
        
        yesLabel.text     = "Yes:"
        noLabel.text      = "No:"
        abstainLabel.text = "Abstain:"
        noVetoLabel.text  = "No (veto):"
        
        totalDeposited.text = "Dep: \(proposal.totalDepopsit)"
        
        yesValLabel.text       = "" + finalYes
        noVallabel.text        = "" + finalNo
        abstainValueLabel.text = "" + finalAbs
        noVetoValueLabel.text  = "" + finalNoV

        yesLabel.textColor = .darkText
        noLabel.textColor = .darkText
        abstainLabel.textColor = .darkText
        noVetoLabel.textColor = .darkText
        if let voterAddr = voter?.address {
            let matches = proposal.votes.filter { $0.voter == voterAddr }
            if let first = matches.first {
                switch first.option {
                case "No": noLabel.textColor             = .pendingYellow
                case "Yes": yesLabel.textColor           = .pendingYellow
                case "Abstain": abstainLabel.textColor   = .pendingYellow
                case "NoWithVeto": noVetoLabel.textColor = .pendingYellow
                default: break
                    
                }
            }
        }
    }
}
