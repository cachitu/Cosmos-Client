//
//  TemplateCollectController.swift
//  Cosmos Client
//
//  Created by Calin Chitu on 12/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit
import MobileCoreServices

struct ColectorScreenData {
    var field1: String?
    var field2: String?
    var field3: String?
    var field4: String?
}

class TemplateCollectController: UIViewController, ToastAlertViewPresentable {
    
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
    
    @IBOutlet weak var topConstraintOutlet: NSLayoutConstraint!
    
    var toast: ToastAlertView?
    
    var collectedData: ColectorScreenData? = ColectorScreenData()
    
    private var fieldsStateDic: [String : Bool] = ["field1" : false, "field2" : false, "field3" : false, "field4" : false]
    
    var onCollectDataComplete: ((_ data: ColectorScreenData?)->())?
    var editMode = false
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        setupTextViews()
        observreFieldsState()
        
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
        self.dismiss(animated: true) {
            self.collectData()
        }
    }
    
    @IBAction func closeButtonAction(_ sender: Any) {
        
        self.view.endEditing(true)
        self.dismiss(animated: true)
    }
    
    private func setupTextViews() {
        //TODO: Add the proper regex when defined by design
        field1RtextField.validationRegex           = RichTextFieldView.validName
        field1RtextField.limitLenght               = 30
        field1RtextField.nextResponderField        = field2RtextField.contentTextField
        field2RtextField.validationRegex        = RichTextFieldView.validName
        field2RtextField.nextResponderField     = field3RtextField.contentTextField
        field3RtextField.validationRegex      = RichTextFieldView.validName
        field3RtextField.nextResponderField   = field4RtextField.contentTextField
        field4RtextField.validationRegex            = RichTextFieldView.validName
    }
    
    private func observreFieldsState() {
        self.addButton.isEnabled = false
        field1RtextField.onFieldStateChange = { [weak self] state in
            self?.fieldsStateDic["field1"] = state
            self?.addButton.isEnabled = self?.canContinue() ?? false
        }
        field2RtextField.onFieldStateChange = { [weak self] state in
            self?.fieldsStateDic["field2"] = state
            self?.addButton.isEnabled = self?.canContinue() ?? false
        }
        field3RtextField.onFieldStateChange = { [weak self] state in
            self?.fieldsStateDic["field3"] = state
            self?.addButton.isEnabled = self?.canContinue() ?? false
        }
        field4RtextField.onFieldStateChange = { [weak self] state in
            self?.fieldsStateDic["field4"] = state
            self?.addButton.isEnabled = self?.canContinue() ?? false
        }
    }
    
    private func canContinue() -> Bool {
        return !self.fieldsStateDic.values.contains(false)
    }
    
    private func collectData() {
        collectedData?.field1 = field1RtextField.contentTextField?.text
        collectedData?.field1 = field2RtextField.contentTextField?.text
        collectedData?.field1 = field3RtextField.contentTextField?.text
        collectedData?.field1 = field4RtextField.contentTextField?.text
        onCollectDataComplete?(collectedData)
    }
    
    private func prePopulate() {
        
        self.fieldsStateDic["field1"] = false
        self.fieldsStateDic["field2"] = false
        self.fieldsStateDic["field3"] = false
        self.fieldsStateDic["field4"] = false
        
        field1RtextField.contentTextField?.text = collectedData?.field1
        field2RtextField.contentTextField?.text = collectedData?.field2
        field3RtextField.contentTextField?.text = collectedData?.field3
        field4RtextField.contentTextField?.text = collectedData?.field4
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
