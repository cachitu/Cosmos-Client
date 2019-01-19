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
    
    var node: GaiaNode? = GaiaNode()
    
    @IBOutlet weak var titleLabelTopConstraint: NSLayoutConstraint!
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    @IBAction func copyAddress(_ sender: Any) {
        UIPasteboard.general.string = addressLabel.text
        toast?.showToastAlert("Address copied to clipboard", autoHideAfter: 5, type: .info, dismissable: true)
    }
    
    @IBAction func copySeed(_ sender: Any) {
        UIPasteboard.general.string = seedLabel.text
        toast?.showToastAlert("Seed copied to clipboard", autoHideAfter: 5, type: .info, dismissable: true)
    }
    
    @IBAction func deleteKey(_ sender: Any) {
        guard let validNode = node else { return }
        key?.deleteKey(node: validNode, password: key?.getPassFromKeychain() ?? "") { success, errMsg in
            if let index = self.selectedkeyIndex {
                self.onDeleteComplete?(index)
            }
            self.dismiss(animated: true)
        }
    }
    
    @IBAction func closeButtonAction(_ sender: Any) {
        
        self.dismiss(animated: true)
    }
    
    private func prePopulate() {
        nameLabel.text = key?.name ?? "No name"
        addressLabel.text = key?.address ?? "cosmos..."
        typeLabel.text = key?.type ?? "..."
        pubKeyLabel.text = key?.pubKey ?? "cosmos..."
        seedLabel.text = "No seed stored in keychain"
        if let seed = key?.getSeedFromKeychain() {
            seedLabel.text = seed
            seedButton.isHidden = false
        }
    }
    
    private func updateUI() {
        
    }
}
