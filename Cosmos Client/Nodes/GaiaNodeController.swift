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
    
    @IBOutlet weak var pickerView: UIPickerView!
    
    @IBOutlet weak var field1RtextField: RichTextFieldView!
    @IBOutlet weak var field2RtextField: RichTextFieldView!
    @IBOutlet weak var field3RtextField: RichTextFieldView!
    @IBOutlet weak var field4RtextField: RichTextFieldView!
    
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var stackHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet weak var topSeparatorView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var topConstraintOutlet: NSLayoutConstraint!
    
    var toast: ToastAlertView?
    
    var collectedData: TDMNode?
    
    private var fieldsStateDic: [String : Bool] = ["field1" : false, "field2" : false, "field3" : true, "field4" : true]
    
    var onCollectDataComplete: ((_ data: TDMNode)->())?
    var onDeleteComplete: ((_ index: Int)->())?
    var editMode = false
    var editedNodeIndex: Int?
    
    var pickerDataSource: [TDMNodeType] {
        return TDMNodeType.allCases
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        setupTextViews()
        observreFieldsState()
        addButton.isHidden = editMode
        titleLabel.text = editMode ? "Edit Node" : "Add Node"
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
    
    @IBAction func closeButtonAction(_ sender: Any) {
        
        self.view.endEditing(true)
        if editMode { self.collectData() }
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
        field1RtextField.onFieldStateChange = { [weak self] state in
            self?.fieldsStateDic["field1"] = state
            self?.addButton.isEnabled = self!.canContinue()
        }
        field2RtextField.onFieldStateChange = { [weak self] state in
            self?.fieldsStateDic["field2"] = state
            self?.addButton.isEnabled = self?.canContinue() ?? false
        }
        field3RtextField.onFieldStateChange = { [weak self] state in
            self?.fieldsStateDic["field3"] = true //port is optionalo
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
        if collectedData == nil { collectedData = TDMNode() }
        collectedData?.name = field1RtextField.contentTextField?.text ?? ""
        collectedData?.host = field2RtextField.contentTextField?.text ?? ""
        collectedData?.rcpPort = Int(field3RtextField.contentTextField?.text ?? "")
        collectedData?.scheme = field4RtextField.contentTextField?.text ?? "http"
        if let data = collectedData {
            onCollectDataComplete?(data)
        }
    }
    
    private func prePopulate() {
        
        field1RtextField.contentTextField?.text = collectedData?.name
        field2RtextField.contentTextField?.text = collectedData?.host
        field3RtextField.contentTextField?.text = collectedData?.rcpPort != nil ? "\(collectedData?.rcpPort ?? 1317)" : ""
        field4RtextField.contentTextField?.text = collectedData?.scheme
        
        self.fieldsStateDic["field1"] = true
        self.fieldsStateDic["field2"] = true
        self.fieldsStateDic["field3"] = true
        self.fieldsStateDic["field4"] = true
        
        if let type = collectedData?.type, let index = pickerDataSource.firstIndex(of: type) {
            pickerView.selectRow(index, inComponent: 0, animated: false)
        }
    }
    
    private func updateUI() {
        
        self.addButton.isEnabled = self.canContinue()
    }
    
    @objc
    func keyboardWillAppear(notification: NSNotification?) {
        
        guard view.frame.size.height <= 568 else { return }
        
        stackHeightConstraint.constant   = 250
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }
    
    @objc
    func keyboardWillDisappear(notification: NSNotification?) {
        
        guard view.frame.size.height <= 568 else { return }
        
        stackHeightConstraint.constant   = 270
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
}

extension GaiaNodeController: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if collectedData == nil { collectedData = TDMNode() }
        collectedData?.type = pickerDataSource[row]
    }
}

extension GaiaNodeController: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataSource.count
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSAttributedString(string: pickerDataSource[row].rawValue, attributes: [NSAttributedString.Key.foregroundColor : UIColor.darkGrayText])
    }

//    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        return pickerDataSource[row].rawValue
//    }
}
