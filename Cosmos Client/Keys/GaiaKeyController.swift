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
    
    var node: TDMNode? = TDMNode()
    var keysDelegate: LocalClient?
    
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet weak var topSeparatorView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var deleteNode: RoundedButton!
    
    @IBOutlet weak var topConstraintOutlet: NSLayoutConstraint!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var pubKeyLabel: UILabel!
    @IBOutlet weak var seedLabel: UILabel!
    @IBOutlet weak var seedButton: UIButton!
    @IBOutlet weak var loadingView: CustomLoadingView!
    @IBOutlet weak var showHideSeedButton: UIButton!
    
    var toast: ToastAlertView?
    var key: GaiaKey?
    
    private var fieldsStateDic: [String : Bool] = ["field1" : false, "field2" : false, "field3" : true, "field4" : true]
    
    var onDeleteComplete: ((_ index: Int)->())?
    var selectedkeyIndex: Int?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        toast = createToastAlert(creatorView: view, holderUnderView: topSeparatorView, holderTopDistanceConstraint: topConstraintOutlet, coveringView: topBarView)
        prePopulate()
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
        toast?.showToastAlert("Address copied to clipboard", autoHideAfter: 15, type: .info, dismissable: true)
    }
    
    @IBAction func copySeed(_ sender: Any) {
        UIPasteboard.general.string = seedLabel.text
        toast?.showToastAlert("Seed copied to clipboard", autoHideAfter: 15, type: .info, dismissable: true)
    }
    
    @IBAction func deleteKey(_ sender: Any) {
        guard let validNode = node else { return }
        let keyName = key?.name ?? "this account"
        var alertMessage = "Enter the password for \(keyName) to delete the wallet. The passowrd and seed will be permanentely removed from the keychain."
        if key?.name == "appleTest1" {
            alertMessage = "This is the Apple Test key, needed for the iOS Appstore review. To delete this address, the password is test1234."
        }
        self.showPasswordAlert(title: nil, message: alertMessage, placeholder: "Minimum 8 characters") { [weak self] pass in
            self?.loadingView.startAnimating()
            self?.key?.unlockKey(node: validNode, password: pass) { [weak self] success, message in
                self?.loadingView.stopAnimating()
                if success == true, let delegate = self?.keysDelegate {
                    self?.key?.deleteKey(node: validNode, clientDelegate: delegate, password: self?.key?.getPassFromKeychain() ?? "") { [weak self] success, errMsg in
                        if success {
                            if let index = self?.selectedkeyIndex {
                                self?.onDeleteComplete?(index)
                            }
                            self?.loadingView.stopAnimating()
                            self?.dismiss(animated: true)
                        } else if let errMessage = errMsg {
                            self?.toast?.showToastAlert(errMessage, autoHideAfter: 15, type: .error, dismissable: true)
                        } else {
                            self?.toast?.showToastAlert("Opps, I failed to delete the key.", autoHideAfter: 15, type: .error, dismissable: true)
                        }
                    }
                } else if let msg = message {
                    self?.toast?.showToastAlert(msg, autoHideAfter: 15, type: .error, dismissable: true)
                } else {
                    self?.toast?.showToastAlert("Opps, I failed.", autoHideAfter: 15, type: .error, dismissable: true)
                }
            }
        }
    }
    
    @IBAction func showOrHideSeed(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        seedLabel.text = "..."
        if sender.isSelected {
            let alertMessage = "Enter the password for \(key?.name ?? "this key") to display the seed."
            self.showPasswordAlert(title: nil, message: alertMessage, placeholder: "Minimum 8 characters") { [weak self] pass in
                if pass == self?.key?.password {
                    self?.seedLabel.text = sender.isSelected ? self?.key?.mnemonic ?? "Unavailable" : "Tap Show Seed to unhide"
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
        nameLabel.text    = key?.name ?? "No name"
        addressLabel.text = key?.address ?? "cosmos..."
        pubKeyLabel.text  = key?.pubAddress ?? "cosmos..."
        typeLabel.text    = key?.type ?? ""
        seedLabel.text    = "Tap Show Seed to unhide"
        if let seed = key?.getMnemonicFromKeychain() {
            seedLabel.text = seed
        }
    }
    
    private func updateUI() {
        
    }
}
