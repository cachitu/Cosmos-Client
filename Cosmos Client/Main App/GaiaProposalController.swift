//
//  GaiaProposalController.swift
//  Cosmos Client
//
//  Created by kytzu on 21/02/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi

struct ProposalData {
    var title: String = "No Title"
    var description: String = "No description"
    var amount: String = "0"
    var type: ProposalType = .text
}

class GaiaProposalController: UIViewController, ToastAlertViewPresentable {

    @IBOutlet weak var field1RtextField: RichTextFieldView!
    @IBOutlet weak var field2RtextField: RichTextFieldView!
    @IBOutlet weak var stackHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet weak var topSeparatorView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var submitButton: RoundedButton!
    @IBOutlet weak var loadingView: CustomLoadingView!
    
    @IBOutlet weak var stackTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var descTextView: UITextView!
    @IBOutlet weak var topConstraintOutlet: NSLayoutConstraint!
    @IBOutlet weak var pasteButton: UIButton!
    
    var toast: ToastAlertView?
    
    var collectedData: ProposalData = ProposalData()
    
    private var fieldsStateDic: [String : Bool] = ["field1" : false, "field2" : false]
    
    var onCollectDataComplete: ((_ data: ProposalData)->())?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        setupTextViews()
        observreFieldsState()
        
        descTextView.layer.cornerRadius = 5
        descTextView.layer.shadowColor = UIColor.black.cgColor
        descTextView.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        descTextView.layer.masksToBounds = false
        descTextView.layer.shadowRadius = 4.0
        descTextView.layer.shadowOpacity = 0.2
        descTextView.isHidden = false
        
        toast = createToastAlert(creatorView: view, holderUnderView: topSeparatorView, holderTopDistanceConstraint: topConstraintOutlet, coveringView: topBarView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        //        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        //        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        self.submitButton.isEnabled = self.canContinue()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification , object: nil)
        //        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification , object: nil)
    }
    
    @IBAction func submit(_ sender: Any) {
        guard
            let name = field1RtextField.contentTextField?.text,
            let amount = field2RtextField.contentTextField?.text,
            let desc = descTextView.text
        else {
            return
        }
        
        collectedData = ProposalData(title: name, description: desc, amount: amount, type: .text)
        
        let optionMenu = UIAlertController(title: "Proposal Type", message: nil, preferredStyle: .actionSheet)
        let op1 = UIAlertAction(title: "Parameter Change", style: .default) { [weak self] alertAction in
            self?.collectedData.type = .parameter_change
            self?.onCollectDataComplete?(self?.collectedData ?? ProposalData())
            self?.dismiss(animated: true)
        }
        let op2 = UIAlertAction(title: "Software Upgrade", style: .default) { [weak self] alertAction in
            self?.collectedData.type = .software_upgrade
            self?.onCollectDataComplete?(self?.collectedData ?? ProposalData())
            self?.dismiss(animated: true)
        }
        let op3 = UIAlertAction(title: "Text Proposal", style: .default) { [weak self] alertAction in
            self?.collectedData.type = .text
            self?.onCollectDataComplete?(self?.collectedData ?? ProposalData())
            self?.dismiss(animated: true)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        //optionMenu.addAction(op1)
        //optionMenu.addAction(op2)
        optionMenu.addAction(op3)
        optionMenu.addAction(cancelAction)

        self.present(optionMenu, animated: true, completion: nil)

    }
    
    @IBAction func pasteAction(_ sender: Any) {
        descTextView.text = UIPasteboard.general.string
    }
    
    @IBAction func closeButtonAction(_ sender: Any) {
        
        self.view.endEditing(true)
        self.dismiss(animated: true)
    }
    
    private func setupTextViews() {
        field1RtextField.validationRegex    = RichTextFieldView.minOneCharRegex
        field1RtextField.nextResponderField = field2RtextField.contentTextField
        field2RtextField.validationRegex    = RichTextFieldView.minOneCharRegex
    }
    
    private func observreFieldsState() {
        self.submitButton.isEnabled = false
        field1RtextField.onFieldStateChange = { [weak self] state in
            self?.fieldsStateDic["field1"] = state
            self?.submitButton.isEnabled = self?.canContinue() ?? false
        }
        field2RtextField.onFieldStateChange = { [weak self] state in
            self?.fieldsStateDic["field2"] = state
            self?.submitButton.isEnabled = self?.canContinue() ?? false
        }
    }
    
    private func canContinue() -> Bool {
        return !self.fieldsStateDic.values.contains(false)
    }
    
    private func updateUI() {
        
        self.submitButton.isEnabled = self.canContinue()
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
