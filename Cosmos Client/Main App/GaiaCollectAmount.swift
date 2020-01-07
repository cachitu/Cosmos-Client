//
//  GaiaCollectAmount.swift
//  Syncnode
//
//  Created by Calin Chitu on 06/01/2020.
//  Copyright © 2020 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi

class GaiaCollectAmount: UIViewController {

    var denomPower: Double = AppContext.shared.node?.digits ?? 6
    
    private var maxAmountLenght = 7
    private var maxDigitsLenght = 6
    private var selectedAsset: Coin? {
        didSet {
            let dvalPwr = pow(10.0, denomPower)
            let denom = selectedAsset?.denom ?? "?"
            let amount = Double(selectedAsset?.amount ?? "0") ?? 0
            denomBigLabel.text = denom
            denomSmallLabel.text = denom
            availableAmountLabel.text = "\(amount / dvalPwr)"
        }
    }
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var denomBigLabel: UILabel!
    @IBOutlet weak var denomSmallLabel: UILabel!
    @IBOutlet weak var amountSubLabel: UILabel!
    @IBOutlet weak var amountPowerLabel: UILabel!
    @IBOutlet weak var denomPickerView: UIPickerView!
    @IBOutlet weak var amountOrFeeSegment: UISegmentedControl!
    @IBOutlet weak var memoTextField: UITextField!
    @IBOutlet weak var availableAmountLabel: UILabel!
    
    @IBAction func amountOrFeeSegmentAction(_ sender: UISegmentedControl) {
    }
    
    @IBAction func useMaxAmountAction(_ sender: UIButton) {
        let data = availableAmountLabel.text ?? "0"
        digits = Array(data).map { String($0) }
    }
    
    @IBAction func closeAction(_ sender: UIButton) {
        self.view.endEditing(true)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func digitAction(_ sender: RoundedButton) {
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

        if digits.joined() == "0" {
            digits.removeLast()
        }
        digits.append(sender.titleLabel?.text ?? "")
    }
    
    @IBAction func backAction(_ sender: RoundedButton) {
        digits.removeLast()
        if digits.joined().count < 1 {
            digits.append("0")
        }
    }
    
    @IBAction func dotAction(_ sender: RoundedButton) {
        if digits.joined().contains(".") {
            Animations.requireUserAtention(on: amountLabel)
            return
        }
        digits.append(".")
    }
    
    private var digits: [String] = ["0"] {
        didSet {
            if let dval = Double(digits.joined()) {
                let dvalPwr = dval * pow(10.0, denomPower)
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .none
                let pwrnum = NSNumber(value: dvalPwr)
                amountSubLabel.text = numberFormatter.string(from: pwrnum)
                amountLabel.text = digits.joined()
            } else {
                amountLabel.text = "0"
                amountSubLabel.text = "0"
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectedAsset = AppContext.shared.account?.assets.first
        amountPowerLabel.text = "\(Int(denomPower))"
        denomPickerView.isHidden = AppContext.shared.account?.assets.count ?? 0 <= 1
        memoTextField.text = AppContext.shared.node?.defaultMemo
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

extension GaiaCollectAmount: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        self.view.endEditing(true)
        guard AppContext.shared.account?.assets.count ?? 0 > row else { return }

        selectedAsset = AppContext.shared.account?.assets[row]
    }
}

extension GaiaCollectAmount: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return AppContext.shared.account?.assets.count ?? 0
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let string = AppContext.shared.account?.assets[row].denom ?? ""
        return NSAttributedString(string: string, attributes: [NSAttributedString.Key.foregroundColor : UIColor.darkGrayText])
    }
}

extension GaiaCollectAmount: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }
}
