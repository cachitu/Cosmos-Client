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

    @IBOutlet weak var leftLabel: UILabel?
    @IBOutlet weak var leftSubLabel: UILabel?
    @IBOutlet weak var upRightLabel: UILabel?
    @IBOutlet weak var leftImageView: UIImageView?
    @IBOutlet weak var roundedView: RoundedView?
    @IBOutlet weak var stateView: CellStateRoundedView!
    @IBOutlet weak var copyButton: UIButton?
    
    @IBAction func copyAction(_ sender: Any) {
        UIPasteboard.general.string = leftSubLabel?.text
        onCopy?()
    }
    
    var onCopy:(() -> ())?
    
    func configure(key: GaiaKey, amount: String = "", image: UIImage?, reuseMode: Bool) {
        if reuseMode {
            copyButton?.setTitle(key.type, for: .normal)
        }
        stateView.currentState = key.watchMode ? .consumed : .active
        upRightLabel?.text = amount
        leftLabel?.text = key.name
        leftSubLabel?.text = key.address
        if !reuseMode { leftImageView?.image = image }
        roundedView?.backgroundColor = !key.watchMode ? .cellBackgroundColor : .cellBackgroundColorAlpha
    }
}

class GaiaSharesCell: UITableViewCell {

    @IBOutlet weak var leftLabel: UILabel?
    @IBOutlet weak var leftSubLabel: UILabel?
    @IBOutlet weak var upRightLabel: UILabel?
    @IBOutlet weak var leftImageView: UIImageView?
    @IBOutlet weak var roundedView: RoundedView?
    @IBOutlet weak var stateView: CellStateRoundedView!
    @IBOutlet weak var copyButton: UIButton?
    
    @IBAction func copyAction(_ sender: Any) {
        UIPasteboard.general.string = leftSubLabel?.text
        onCopy?()
    }
    
    var onCopy:(() -> ())?
    
    func configure(key: GaiaKey?, delegation: GaiaDelegation, validatorName: String) {
        
        let parts = delegation.shares.split(separator: ".")

        leftLabel?.text = "\(parts.first ?? "0") shares to " + validatorName
        leftSubLabel?.text = delegation.validatorAddr
        leftLabel?.textColor = .darkGrayText
        if AppContext.shared.node?.type == .iris || AppContext.shared.node?.type == .iris_fuxi {
            upRightLabel?.text = delegation.availableReward + "💰"
        } else {
            upRightLabel?.text = delegation.availableRewardNormalised(decimals: AppContext.shared.nodeDecimals, displayDecimnals: 2) + "💰"
        }
        roundedView?.backgroundColor = key?.watchMode == true ? .cellBackgroundColorAlpha : .cellBackgroundColor
    }
}
