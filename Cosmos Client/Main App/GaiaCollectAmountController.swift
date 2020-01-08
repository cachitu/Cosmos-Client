//
//  GaiaCollectAmount.swift
//  Syncnode
//
//  Created by Calin Chitu on 06/01/2020.
//  Copyright © 2020 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi

class GaiaCollectAmountController: UIViewController {

    var onConfirm: (() -> ())?
    var onlyFeeMode = AppContext.shared.collectOnlyFee
    var stakingOperation = AppContext.shared.colletForStaking
    
    private var denomPower: Double = AppContext.shared.node?.decimals ?? 6
    private var maxAmountLenght = 7
    private var maxDigitsLenght = 6
    private var selectedAsset: Coin? {
        didSet {
            let denom = selectedAsset?.denom ?? ""
            AppContext.shared.collectedDenom = denom
            denomBigLabel.text = selectedAsset?.upperDenom ?? ""
            denomSmallLabel.text = denom
            availableAmountLabel.text = selectedAsset?.deflatedAmount(decimals: Int(AppContext.shared.node?.decimals ?? 6), displayDecimnals: 6)
        }
    }
    
    private var isCollectingFee: Bool {
        return amountOrFeeSegment.selectedSegmentIndex == 1
    }
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var denomBigLabel: UILabel!
    @IBOutlet weak var denomSmallLabel: UILabel!
    @IBOutlet weak var amountSubLabel: UILabel!
    @IBOutlet weak var denomPickerView: UIPickerView!
    @IBOutlet weak var amountOrFeeSegment: UISegmentedControl!
    @IBOutlet weak var memoTextField: UITextField!
    @IBOutlet weak var availableAmountLabel: UILabel!
    @IBOutlet weak var maxAvailableLeadingLabel: UILabel!
    @IBOutlet weak var feeCurentSettingsLabel: UILabel!
    
    @IBOutlet weak var confirmButton: UIButton!
    
    @IBAction func closeAction(_ sender: UIButton) {
        AppContext.shared.collectedAmount = "0"
        AppContext.shared.collectedDenom = ""
        self.view.endEditing(true)
        self.dismiss(animated: true, completion: nil)
    }
    

    @IBAction func confirmAction(_ sender: UIButton) {
        AppContext.shared.node?.defaultMemo = memoTextField.text ?? ""
        self.peristNodes()
        self.view.endEditing(true)
        self.dismiss(animated: true) {
            self.onConfirm?()
        }
    }
    
    @IBAction func amountOrFeeSegmentAction(_ sender: UISegmentedControl) {
        denomPickerView.reloadAllComponents()
        if sender.selectedSegmentIndex == 1 {
            updateForFeeState()
        }
        if sender.selectedSegmentIndex == 0 {
            maxAvailableLeadingLabel.text = "Available:"
            updatableDigits = digits
            let tmpAsset = selectedAsset
            selectedAsset = tmpAsset
        }
        updatableDigits[0] = updatableDigits.first ?? "0"
    }
    
    @IBAction func useMaxAmountAction(_ sender: UIButton) {
        let data = availableAmountLabel.text ?? "0"
        updatableDigits = Array(data).map { String($0) }
    }
    
    @IBAction func digitAction(_ sender: RoundedButton) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        self.view.endEditing(true)
        let parts = digits.joined().split(separator: ".")
        if parts.count == 1, parts.first?.count ?? 0 >= maxAmountLenght, digits.last != "." {
            Animations.requireUserAtention(on: amountLabel)
            return
        }
        if parts.count == 2, parts.last?.count ?? 0 >= maxDigitsLenght {
            Animations.requireUserAtention(on: amountLabel)
            return
        }
        
        updatableDigits = digits
        if updatableDigits.joined() == "0" {
            updatableDigits.removeLast()
        }
        updatableDigits.append(sender.titleLabel?.text ?? "")
    }
    
    @IBAction func backAction(_ sender: RoundedButton) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        updatableDigits = digits
        updatableDigits.removeLast()
        if updatableDigits.joined().count < 1 {
            updatableDigits.append("0")
        }
    }
    
    @IBAction func dotAction(_ sender: RoundedButton) {
        updatableDigits = digits
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        if updatableDigits.joined().contains(".") {
            Animations.requireUserAtention(on: amountLabel)
            return
        }
        updatableDigits.append(".")
    }
    
    private var digits: [String] {
        return isCollectingFee ? feeDigits : amountDigits
    }
    
    private var updatableDigits: [String] = ["0"] {
        didSet {
            if isCollectingFee {
                feeDigits = updatableDigits
            } else {
                amountDigits = updatableDigits
            }
        }
    }
    private var amountDigits: [String] = ["0"] {
        didSet {
            if let dval = Double(amountDigits.joined()) {
                let dvalPwr = dval * pow(10.0, denomPower)
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .none
                let pwrnum = NSNumber(value: dvalPwr)
                amountSubLabel.text = numberFormatter.string(from: pwrnum)
                amountLabel.text = amountDigits.joined()
                AppContext.shared.collectedAmount = amountSubLabel.text ?? "0"
            } else {
                amountLabel.text = "0"
                amountSubLabel.text = "0"
            }
        }
    }

    private var feeDigits: [String] = ["0"] {
        didSet { updateFeeDigits() }
    }

    private func updateFeeDigits() {
        if let dval = Double(feeDigits.joined()) {
            let dvalPwr = dval * pow(10.0, denomPower)
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .none
            let pwrnum = NSNumber(value: dvalPwr)
            let formatted = numberFormatter.string(from: pwrnum) ?? "0"
            amountSubLabel.text = formatted
            let feeDenom = AppContext.shared.node?.feeDenom ?? ""
            feeCurentSettingsLabel.text = formatted + " " + feeDenom
            amountLabel.text = feeDigits.joined()
            AppContext.shared.node?.feeAmount = amountSubLabel.text ?? "0"
        } else {
            amountLabel.text = "0"
            amountSubLabel.text = "0"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AppContext.shared.collectedAmount = "0"
        selectedAsset = AppContext.shared.account?.assets.first
        if AppContext.shared.node?.feeDenom == "" {
            AppContext.shared.node?.feeDenom = selectedAsset?.denom ?? ""
        }
        denomPickerView.isHidden = AppContext.shared.account?.assets.count ?? 0 <= 1
        memoTextField.text = AppContext.shared.node?.defaultMemo
        let fee = AppContext.shared.node?.feeAmount ?? "0"
        let feeDenom = AppContext.shared.node?.feeDenom ?? ""
        feeCurentSettingsLabel.text = fee + " " + feeDenom
        
        if onlyFeeMode {
            amountOrFeeSegment.selectedSegmentIndex = 1
            amountOrFeeSegment.isEnabled = false
            updateForFeeState()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    private func updateForFeeState() {
        let fee = AppContext.shared.node?.feeAmount ?? "0"
        let dfee = Double(fee) ?? 0.0
        let strVal = dfee > 0 ? "\(dfee / pow(10.0, denomPower))" : "0"
        updatableDigits = Array(strVal).map { String($0) }
        availableAmountLabel.text = "1"
        let feeDenom = AppContext.shared.node?.feeDenom ?? ""
        denomBigLabel.text = Coin.upperDenomFrom(denom: feeDenom)
        denomSmallLabel.text = AppContext.shared.node?.feeDenom
        maxAvailableLeadingLabel.text = "Max Fee:"
    }
    

    private func peristNodes() {
        if let savedNodes = PersistableGaiaNodes.loadFromDisk() as? PersistableGaiaNodes, let validNode = AppContext.shared.node {
            for savedNode in savedNodes.nodes {
                if savedNode.network == validNode.network {
                    savedNode.feeAmount  = validNode.feeAmount
                    savedNode.feeDenom  = validNode.feeDenom
                    savedNode.defaultMemo = validNode.defaultMemo
                }
            }
            PersistableGaiaNodes(nodes: savedNodes.nodes).savetoDisk()
        }
    }
    
    private var pickerDataSource: [Coin] {
        if stakingOperation, !isCollectingFee, let first = AppContext.shared.account?.assets.first {
            
            return [first]
        }
        return AppContext.shared.account?.assets ?? []
    }
}

extension GaiaCollectAmountController: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        self.view.endEditing(true)
        guard pickerDataSource.count > row else { return }

        let coin = pickerDataSource[row]
        if isCollectingFee {
            AppContext.shared.node?.feeDenom = coin.denom ?? ""
            denomBigLabel.text = coin.upperDenom
            denomSmallLabel.text = coin.denom
        } else {
            selectedAsset = coin
        }
    }
}

extension GaiaCollectAmountController: UIPickerViewDataSource {
    
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataSource.count
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let string = pickerDataSource[row].denom ?? ""
        return NSAttributedString(string: string, attributes: [NSAttributedString.Key.foregroundColor : UIColor.darkGrayText])
    }
}

extension GaiaCollectAmountController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }
}
