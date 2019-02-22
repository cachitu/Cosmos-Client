//
//  GaiaTransactiionsController.swift
//  Cosmos Client
//
//  Created by Calin Chitu on 14/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi

class GaiaSettingsController: UIViewController, ToastAlertViewPresentable {

    var node: GaiaNode?
    var key: GaiaKey?
    var account: GaiaAccount?
    var feeAmount: String { return node?.defaultTxFee  ?? "0" }

    var toast: ToastAlertView?
    
    @IBOutlet weak var loadingView: CustomLoadingView!
    @IBOutlet weak var toastHolderUnderView: UIView!
    @IBOutlet weak var toastHolderTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var topNavBarView: UIView!
    @IBOutlet weak var bottomTabbarView: CustomTabBar!
    @IBOutlet weak var bottomTabbarDownConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var feeSectionTitleLabel: UILabel!
    @IBOutlet weak var feeTextField: UITextField!
    @IBOutlet weak var feeApplyButton: UIButton!
    
    
    var forwardCounter = 0
    var onUnwind: ((_ toIndex: Int) -> ())?

    @IBAction func applyFee(_ sender: Any) {
        feeTextField.resignFirstResponder()
        if let value = feeTextField.text {
            node?.defaultTxFee = value
            updateFeeLabel()
            if let savedNodes = PersistableGaiaNodes.loadFromDisk() as? PersistableGaiaNodes, let validNode = node {
                for savedNode in savedNodes.nodes {
                    if savedNode.network == validNode.network {
                        savedNode.defaultTxFee = validNode.defaultTxFee
                    }
                }
                PersistableGaiaNodes(nodes: savedNodes.nodes).savetoDisk()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toast = createToastAlert(creatorView: view, holderUnderView: toastHolderUnderView, holderTopDistanceConstraint: toastHolderTopConstraint, coveringView: topNavBarView)
        bottomTabbarView.selectIndex(3)
        bottomTabbarView.onTap = { [weak self] index in
            switch index {
            case 0:
                self?.onUnwind?(0)
                self?.performSegue(withIdentifier: "UnwindToWallet", sender: nil)
            case 1:
                self?.onUnwind?(1)
                self?.performSegue(withIdentifier: "UnwindToValidators", sender: nil)
            case 2: self?.dismiss(animated: false)
            default: break
            }
        }
        updateFeeLabel()
    }
    
    func updateFeeLabel() {
        var feeText = "Set the default fee for this node. It will apply to all types of transactions"
        if let amount = node?.defaultTxFee, let denom = account?.feeDenom {
            feeText += " (current settings: \(amount) \(denom))"
            if Double(amount) ?? 0 > 0.0 {
                feeTextField.text = amount
            }
        }
        feeSectionTitleLabel.text = feeText
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
    
    @IBAction func unwindToTarnsactions(segue:UIStoryboardSegue) {
        bottomTabbarView.selectIndex(3)
    }

}
