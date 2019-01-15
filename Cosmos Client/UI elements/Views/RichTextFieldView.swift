//
//  RichTextFieldView.swift
//  IPSXSandbox
//
//  Created by Calin Chitu on 18/04/2018.
//  Copyright © 2018 Calin Chitu. All rights reserved.
//

import UIKit

class RichTextFieldView: UIView {
    
    static let validEmailRegex    = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    static let validPasswordRegex = "^.{8,}$"
    static let validEthAddress    = "(0x){1}[0-9a-fA-F]{40}"
    static let validName          = "^[A-Za-z0-9- ]+$"
    static let minOneCharRegex    = "^.{1,}$"
    static let validTelegramID    = "(@){1}[A-Za-z0-9_]{5,32}"

    var onFieldStateChange: ((_ newState: Bool)->())?
    var limitLenght: Int = 0
    
    var nextResponderField: UIResponder? = nil
    var validationRegex: String? = nil
    var mathingTextField: UITextField? = nil
    
    var isContentValid: Bool {
        return isValid(text: contentTextField?.text ?? "")
    }
    
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var invalidContentLabel: UILabel?
    @IBOutlet weak var leftIconImageView: UIView?
    @IBOutlet weak var separatorView: UIView?
    @IBOutlet weak var contentTextField: UITextField? {
        didSet {
            contentTextField?.delegate = self
            contentTextField?.addTarget(self, action: #selector(textFieldEditingChanged(_:)), for: .editingChanged)
            if let placeholder = contentTextField?.placeholder {
                contentTextField?.attributedPlaceholder = NSAttributedString(string:placeholder,
                                                                         attributes: [NSAttributedString.Key.foregroundColor: UIColor.silver])
            }
         }
    }
    
    public func refreshStatus() {
        let currentText = contentTextField?.text ?? ""
        updateColors(isValid: isValid(text: currentText))
    }
    
    private func updateColors(isValid: Bool) {
        
        let chars = contentTextField?.text?.count ?? 0
        onFieldStateChange?(isValid)
        
        invalidContentLabel?.isHidden  = isValid || chars == 0
        titleLabel?.textColor          = isValid || chars == 0 ? .warmGrey : .inputError
        separatorView?.backgroundColor = chars == 0 ? .silverAlpha : isValid ? .lightBlue : .inputError
        leftIconImageView?.tintColor   = separatorView?.backgroundColor
        contentTextField?.textColor    = isValid || chars == 0 ? .darktext : .inputError
    }
    
    private func isMatchingOtherField() -> Bool {
        guard let text = mathingTextField?.text else { return true }
        return contentTextField?.text == text
    }
    
    private func isValid(text: String) -> Bool {
        guard let regexString = validationRegex else { return true }
        let validityTest = NSPredicate(format:"SELF MATCHES %@", regexString)
        return validityTest.evaluate(with: text) && isMatchingOtherField()
    }
}

extension RichTextFieldView: UITextFieldDelegate {
    
    @objc func textFieldEditingChanged(_ textField: UITextField) {
        if let newString = textField.text {
            updateColors(isValid: isValid(text: newString))
       }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        guard  !textField.isSecureTextEntry else { return true }
        
        let newString = NSString(string: textField.text!).replacingCharacters(in: range, with: string)
        updateColors(isValid: isValid(text: newString))
        if limitLenght > 0, newString.count >= limitLenght {
            return false
        }
        return true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleTextfieldFocusChange(for: textField, actionOnDone: true)
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        textField.returnKeyType = nextResponderField != nil ? .next : .done
        return true
    }
    
    private func handleTextfieldFocusChange(for textField: UITextField, actionOnDone: Bool) {
        updateColors(isValid: isValid(text: textField.text ?? ""))
        if let nextField = nextResponderField {
            nextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
    }
}
