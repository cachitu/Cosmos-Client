//
//  GaiaKeyCreateController.swift
//  Cosmos Client
//
//  Created by Calin Chitu on 15/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi

class GaiaKeyCreateController: UIViewController, ToastAlertViewPresentable, GaiaKeysManagementCapable {
    
    var node: TDMNode? = TDMNode()
    var keysDelegate: LocalClient?
    
    @IBOutlet weak var field1RtextField: RichTextFieldView!
    @IBOutlet weak var field2RtextField: RichTextFieldView!
    @IBOutlet weak var stackHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet weak var topSeparatorView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var deleteNode: RoundedButton!
    @IBOutlet weak var loadingView: CustomLoadingView!
    
    @IBOutlet weak var stackTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var seedTextView: UITextView!
    @IBOutlet weak var topConstraintOutlet: NSLayoutConstraint!
    @IBOutlet weak var pasteButton: UIButton!
    
    var toast: ToastAlertView?
    
    var collectedData: GaiaKey?
    
    private var fieldsStateDic: [String : Bool] = ["field1" : false, "field2" : false]
    
    var onCollectDataComplete: ((_ data: GaiaKey)->())?
    var onCreateComplete: (()->())?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        setupTextViews()
        observreFieldsState()
        
        seedTextView.layer.cornerRadius = 5
        seedTextView.layer.shadowColor = UIColor.black.cgColor
        seedTextView.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        seedTextView.layer.masksToBounds = false
        seedTextView.layer.shadowRadius = 4.0
        seedTextView.layer.shadowOpacity = 0.2
        seedTextView.isHidden = true
        
        toast = createToastAlert(creatorView: view, holderUnderView: topSeparatorView, holderTopDistanceConstraint: topConstraintOutlet, coveringView: topBarView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        self.deleteNode.isEnabled = self.canContinue()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
//        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification , object: nil)
//        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification , object: nil)
    }
    
    @IBAction func seedRecover(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        seedTextView.isHidden = !sender.isSelected
        pasteButton.isHidden = !sender.isSelected
    }
    
    @IBAction func createKey(_ sender: Any) {
        guard let validNode = node, let name = field1RtextField.contentTextField?.text, let pass = field2RtextField.contentTextField?.text, let keysDelegate = keysDelegate else {
            return
        }
        
        let seedOk = seedTextView.isHidden || seedTextView.text.split(separator: " ").count == 24

        guard seedOk else {
            toast?.showToastAlert("The seed must have 24 words", autoHideAfter: 15, type: .info, dismissable: true)
            return
        }
        
        var seed: String? = nil
        if seedTextView.isHidden == false, let text = seedTextView.text {
            let words = text.components(separatedBy: " ")
            if words.count == 24 {
                seed = text }
        }
        self.loadingView.startAnimating()
        self.createKey(node: validNode, clientDelegate: keysDelegate, name: name, pass: pass, seed: seed) { [weak self] key, error in
            DispatchQueue.main.async {
                self?.loadingView.stopAnimating()
                if let validKey = key {
                    
                    if let savedKeys = PersistableGaiaKeys.loadFromDisk() as? PersistableGaiaKeys {
                        var list = savedKeys.keys
                        list.append(validKey)
                        PersistableGaiaKeys(keys: list).savetoDisk()
                    }
                    
                    if let storedBook = GaiaAddressBook.loadFromDisk() as? GaiaAddressBook {
                        var addrItems: [GaiaAddressBookItem] = []
                        let item = GaiaAddressBookItem(name: validKey.name, address: validKey.address)
                        addrItems.append(item)
                        storedBook.items.mergeElements(newElements: addrItems)
                        storedBook.savetoDisk()
                    }

                    self?.dismiss(animated: true)
                } else if let errMsg = error {
                    self?.toast?.showToastAlert(errMsg, autoHideAfter: 15, type: .info, dismissable: true)
                } else {
                    self?.toast?.showToastAlert("Ooops! I failed!", autoHideAfter: 15, type: .info, dismissable: true)
                }
            }
        }
    }
    
    @IBAction func pasteAction(_ sender: Any) {
        seedTextView.text = UIPasteboard.general.string
    }
    
    @IBAction func closeButtonAction(_ sender: Any) {
        
        self.view.endEditing(true)
        self.dismiss(animated: true)
    }
    
    private func setupTextViews() {
        field1RtextField.validationRegex    = RichTextFieldView.minOneCharRegex
        field1RtextField.nextResponderField = field2RtextField.contentTextField
        field2RtextField.validationRegex    = RichTextFieldView.validPasswordRegex
     }
    
    private func observreFieldsState() {
        self.deleteNode.isEnabled = false
        field1RtextField.onFieldStateChange = { [weak self] state in
            self?.fieldsStateDic["field1"] = state
            self?.deleteNode.isEnabled = self?.canContinue() ?? false
        }
        field2RtextField.onFieldStateChange = { [weak self] state in
            self?.fieldsStateDic["field2"] = state
            self?.deleteNode.isEnabled = self?.canContinue() ?? false
        }
    }
    
    private func canContinue() -> Bool {
        return !self.fieldsStateDic.values.contains(false)
    }
    
    private func collectData() {
        if collectedData == nil {  }
        if let data = collectedData {
            onCollectDataComplete?(data)
        }
    }
    
    private func updateUI() {
        
        self.deleteNode.isEnabled = self.canContinue()
    }
    
    @objc
    func keyboardWillAppear(notification: NSNotification?) {
        
        guard view.frame.size.height <= 568 else { return }
        
        stackTopConstraint.constant = -30
        stackHeightConstraint.constant   = 270
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }
    
    @objc
    func keyboardWillDisappear(notification: NSNotification?) {
        
        guard view.frame.size.height <= 568 else { return }
        
        stackTopConstraint.constant = 26
        stackHeightConstraint.constant   = 320
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
}
