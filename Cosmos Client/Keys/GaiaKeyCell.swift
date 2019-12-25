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
    
    @IBAction func copyAction(_ sender: Any) {
        UIPasteboard.general.string = leftSubLabel?.text
        onCopy?()
    }
    
    var onCopy:(() -> ())?
    
    func configure(key: GaiaKey, amount: String = "", image: UIImage?) {
        stateView.currentState = key.watchMode ? .consumed : .active
        upRightLabel?.text = amount
        leftLabel?.text = key.name
        leftSubLabel?.text = key.address
        leftImageView?.image = image
        roundedView?.backgroundColor = key.watchMode ? UIColor(named: "WatchModeBackground") : .white
    }
}
