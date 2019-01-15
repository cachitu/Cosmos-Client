//
//  GaiaNodeController.swift
//  Cosmos Client
//
//  Created by Calin Chitu on 12/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi

class GaiaNodeController: UIViewController, ToastAlertViewPresentable {
    
    @IBOutlet weak var field1RtextField: RichTextFieldView!
    @IBOutlet weak var field2RtextField: RichTextFieldView!
    @IBOutlet weak var field3RtextField: RichTextFieldView!
    @IBOutlet weak var field4RtextField: RichTextFieldView!
    
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var titleLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var stackHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet weak var topSeparatorView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var deleteNode: RoundedButton!
    @IBOutlet weak var moreDetails: RoundedButton!
    
    @IBOutlet weak var topConstraintOutlet: NSLayoutConstraint!
    
    var toast: ToastAlertView?
    
    var collectedData: GaiaNode?
    
    private var fieldsStateDic: [String : Bool] = ["field1" : false, "field2" : false, "field3" : true, "field4" : true]
    
    var onCollectDataComplete: ((_ data: GaiaNode)->())?
    var onDeleteComplete: ((_ index: Int)->())?
    var editMode = false
    var editedNodeIndex: Int?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        setupTextViews()
        observreFieldsState()
        deleteNode.isHidden = !editMode
        moreDetails.isHidden = !editMode
        
        if editMode {
            prePopulate()
        }
        toast = createToastAlert(creatorView: view, holderUnderView: topSeparatorView, holderTopDistanceConstraint: topConstraintOutlet, coveringView: topBarView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        self.addButton.isEnabled = self.canContinue()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification , object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification , object: nil)
    }
    
    @IBAction func collectAndClose(_ sender: Any) {
        self.view.endEditing(true)
        self.collectData()
        self.dismiss(animated: true)
    }
    
    @IBAction func deleteNode(_ sender: Any) {
        self.view.endEditing(true)
        if let index = editedNodeIndex {
            onDeleteComplete?(index)
        }
        self.dismiss(animated: true)
    }
    
    @IBAction func closeButtonAction(_ sender: Any) {
        
        self.view.endEditing(true)
        self.dismiss(animated: true)
    }
    
    private func setupTextViews() {
        field1RtextField.validationRegex    = RichTextFieldView.minOneCharRegex
        field1RtextField.nextResponderField = field2RtextField.contentTextField
        field2RtextField.validationRegex    = RichTextFieldView.minOneCharRegex
        field2RtextField.nextResponderField = field3RtextField.contentTextField
        field3RtextField.validationRegex    = RichTextFieldView.minOneCharRegex
        field3RtextField.nextResponderField = field4RtextField.contentTextField
        field4RtextField.validationRegex    = RichTextFieldView.minOneCharRegex
    }
    
    private func observreFieldsState() {
        self.addButton.isEnabled = false
        field1RtextField.onFieldStateChange = { state in
            self.fieldsStateDic["field1"] = state
            self.addButton.isEnabled = self.canContinue()
        }
        field2RtextField.onFieldStateChange = { state in
            self.fieldsStateDic["field2"] = state
            self.addButton.isEnabled = self.canContinue()
        }
        field3RtextField.onFieldStateChange = { state in
            self.fieldsStateDic["field3"] = state
            self.addButton.isEnabled = self.canContinue()
        }
        field4RtextField.onFieldStateChange = { state in
            self.fieldsStateDic["field4"] = state
            self.addButton.isEnabled = self.canContinue()
        }
    }
    
    private func canContinue() -> Bool {
        return !self.fieldsStateDic.values.contains(false)
    }
    
    private func collectData() {
        if collectedData == nil { collectedData = GaiaNode() }
        collectedData?.name = field1RtextField.contentTextField?.text ?? ""
        collectedData?.host = field2RtextField.contentTextField?.text ?? ""
        collectedData?.rcpPort = Int(field3RtextField.contentTextField?.text ?? "1317") ?? 1317
        collectedData?.tendermintPort = Int(field4RtextField.contentTextField?.text ?? "26657") ?? 1317
        if let data = collectedData {
            onCollectDataComplete?(data)
        }
    }
    
    private func prePopulate() {
        
        field1RtextField.contentTextField?.text = collectedData?.name
        field2RtextField.contentTextField?.text = collectedData?.host
        field3RtextField.contentTextField?.text = "\(collectedData?.rcpPort ?? 1317)"
        field4RtextField.contentTextField?.text = "\(collectedData?.tendermintPort ?? 26657)"
        
        self.fieldsStateDic["field1"] = true
        self.fieldsStateDic["field2"] = true
        self.fieldsStateDic["field3"] = true
        self.fieldsStateDic["field4"] = true
    }
    
    private func updateUI() {
        
        self.addButton.isEnabled = self.canContinue()
    }
    
    @objc
    func keyboardWillAppear(notification: NSNotification?) {
        
        guard view.frame.size.height <= 568 else { return }
        
        titleLabelTopConstraint.constant = -30
        stackHeightConstraint.constant   = 270
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }
    
    @objc
    func keyboardWillDisappear(notification: NSNotification?) {
        
        guard view.frame.size.height <= 568 else { return }
        
        titleLabelTopConstraint.constant = 26
        stackHeightConstraint.constant   = 320
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
}
