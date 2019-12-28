//
//  GaiaKeyController.swift
//  Cosmos Client
//
//  Created by Calin Chitu on 14/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi

class GaiaKeyController: UIViewController, ToastAlertViewPresentable {
    
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet weak var topSeparatorView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var deleteNode: RoundedButton!
    
    @IBOutlet weak var topConstraintOutlet: NSLayoutConstraint!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    
    @IBOutlet weak var pubKeyTitle: UILabel!
    @IBOutlet weak var pubKeyLabel: UILabel!
    
    @IBOutlet weak var seedTitle: UILabel!
    @IBOutlet weak var seedLabel: UILabel!
    @IBOutlet weak var seedButton: UIButton!
    @IBOutlet weak var loadingView: CustomLoadingView!
    @IBOutlet weak var showHideSeedButton: UIButton!
    
    var toast: ToastAlertView?
    
    private var fieldsStateDic: [String : Bool] = ["field1" : false, "field2" : false, "field3" : true, "field4" : true]
    
    var onDeleteComplete: ((_ index: Int)->())?
    var selectedkeyIndex: Int?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        toast = createToastAlert(creatorView: view, holderUnderView: topSeparatorView, holderTopDistanceConstraint: topConstraintOutlet, coveringView: topBarView)
        prePopulate()
        if AppContext.shared.key?.watchMode == true {
            pubKeyTitle.isHidden = true
            pubKeyLabel.isHidden = true
            seedTitle.isHidden = true
            seedLabel.isHidden = true
            seedButton.isHidden = true
            showHideSeedButton.isHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        seedLabel.text = "Tap Show Seed to unhide"
        showHideSeedButton.isSelected = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    @IBAction func copyAddress(_ sender: Any) {
        UIPasteboard.general.string = addressLabel.text
        toast?.showToastAlert("Address copied to clipboard", autoHideAfter: GaiaConstants.autoHideToastTime, type: .info, dismissable: true)
    }
    
    @IBAction func copySeed(_ sender: Any) {
        UIPasteboard.general.string = seedLabel.text
        toast?.showToastAlert("Seed copied to clipboard", autoHideAfter: GaiaConstants.autoHideToastTime, type: .info, dismissable: true)
    }
    
    @IBAction func deleteKey(_ sender: Any) {
    }
    
    @IBAction func showOrHideSeed(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        seedLabel.text = "..."
        if sender.isSelected {
            let alertMessage = "Enter the password for \(AppContext.shared.key?.name ?? "this key") to display the seed."
            self.showPasswordAlert(title: nil, message: alertMessage, placeholder: "Minimum 8 characters") { [weak self] pass in
                if pass == AppContext.shared.key?.password {
                    self?.seedLabel.text = sender.isSelected ? AppContext.shared.key?.mnemonic ?? "Unavailable" : "Tap Show Seed to unhide"
                } else {
                    sender.isSelected = false
                    self?.seedLabel.text = "Wrong password"
                }
            }
        } else {
            seedLabel.text = "Tap Show Seed to unhide"
        }
    }
    
    @IBAction func closeButtonAction(_ sender: Any) {
        
        self.dismiss(animated: true)
    }
    
    private func prePopulate() {
        nameLabel.text    = AppContext.shared.key?.name ?? "No name"
        addressLabel.text = AppContext.shared.key?.address ?? "cosmos..."
        pubKeyLabel.text  = AppContext.shared.key?.pubAddress ?? "cosmos..."
        typeLabel.text    = AppContext.shared.key?.type ?? ""
        seedLabel.text    = "Tap Show Seed to unhide"
        if let seed = AppContext.shared.key?.getMnemonicFromKeychain() {
            seedLabel.text = seed
        }
    }
    
    private func updateUI() {
        
    }
}
