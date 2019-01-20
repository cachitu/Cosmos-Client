//
//  GaiaWalletController.swift
//  Cosmos Client
//
//  Created by Calin Chitu on 14/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi

class GaiaWalletController: UIViewController, ToastAlertViewPresentable, GaiaKeysManagementCapable {
    
    var node: GaiaNode?
    var key: GaiaKey?
    var account: GaiaAccount?
    
    var toast: ToastAlertView?
    
    @IBOutlet weak var loadingView: CustomLoadingView!
    @IBOutlet weak var toastHolderUnderView: UIView!
    @IBOutlet weak var toastHolderTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var topNavBarView: UIView!
    @IBOutlet weak var bottomTabbarView: CustomTabBar!
    @IBOutlet weak var bottomTabbarDownConstraint: NSLayoutConstraint!
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var amountTitleLabel: UILabel!
    @IBOutlet weak var amountValueLabel: UILabel!
    @IBOutlet weak var amountDenomLabel: UILabel!
    @IBOutlet weak var feeAmountValueLabel: UILabel!
    @IBOutlet weak var feeAmountDenomLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var sendAmountTextField: UITextField!
    @IBOutlet weak var sendAmountButton: RoundedButton!
    @IBOutlet weak var denomPickerView: UIPickerView!
    
    @IBOutlet weak var qrTestImageView: UIImageView!
    @IBAction func backAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBOutlet weak var topConstraintOutlet: NSLayoutConstraint!

    private var selectedAsset: Coin?
    private var senderAddress: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toast = createToastAlert(creatorView: view, holderUnderView: toastHolderUnderView, holderTopDistanceConstraint: toastHolderTopConstraint, coveringView: topNavBarView)
        bottomTabbarView.selectIndex(0)
        bottomTabbarView.onTap = { index in
            switch index {
            case 1:
                self.performSegue(withIdentifier: "nextSegue", sender: index)
            case 2:
                self.performSegue(withIdentifier: "nextSegue", sender: index)
                UIView.setAnimationsEnabled(false)
            case 3:
                self.performSegue(withIdentifier: "nextSegue", sender: index)
                UIView.setAnimationsEnabled(false)
            default: break
            }
        }
        amountValueLabel.text = ""
        amountDenomLabel.text = ""
        feeAmountValueLabel.text = ""
        feeAmountDenomLabel.text = ""
        
        if let validKey = key {
            qrTestImageView.image = UIImage.getQRCodeImage(from: validKey.address)
            amountTitleLabel.text = validKey.name
            addressLabel.text     = validKey.address
        }
        sendAmountButton.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        loadingView.startAnimating()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        bottomTabbarView.selectIndex(0)
        if let addrToSend = senderAddress, let denom = selectedAsset?.denom {
            sendAssets(node: node!,
                       key: key!,
                       toAddress: addrToSend,
                       amount: sendAmountTextField.text ?? "0",
                       denom: denom) { response, error in
                        DispatchQueue.main.async {
                            if let validResponse = response {
                                self.toast?.showToastAlert("Hash [\(validResponse.hash ?? "...")] submited", autoHideAfter: 4, type: .validatePending, dismissable: false)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                    self.loadData()
                                }
                           } else if let errMsg = error {
                                self.loadingView.stopAnimating()
                                self.toast?.showToastAlert(errMsg, autoHideAfter: 5, type: .error, dismissable: true)
                            } else {
                                self.loadingView.stopAnimating()
                                self.toast?.showToastAlert("Ooops, I failed.", autoHideAfter: 5, type: .error, dismissable: true)
                           }
                        }
            }
            senderAddress = nil
        } else {
            loadData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification , object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification , object: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowAddressBookSegue" {
            let nav = segue.destination as? UINavigationController
            let dest = nav?.viewControllers.first as? AddressesListController
            dest?.shouldPop = true
            dest?.onSelectAddress = { selected in
                if let validAddress = selected {
                    self.senderAddress = validAddress.address
                }
            }
        }
        if segue.identifier == "nextSegue" {
            if let index = sender as? Int {
                let dest = segue.destination as? GaiaValidatorsController
                dest?.forwardCounter = index - 1
            }
        }
    }
    
    @IBAction func shareAddress(_ sender: Any) {
        
        let text = key?.address ?? ""
        let textShare = [ text ]
        let activityViewController = UIActivityViewController(activityItems: textShare , applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func unwindToWallet(segue:UIStoryboardSegue) {
        bottomTabbarView.selectIndex(0)
    }
    
    @IBAction func sendAction(_ sender: Any) {
        self.performSegue(withIdentifier: "ShowAddressBookSegue", sender: self)
    }
    
    private func loadData() {
        
        if let validNode = node, let validKey = key {
            getAccount(node: validNode, key: validKey) { account, errMessage in
                
                self.loadingView.stopAnimating()
                self.amountValueLabel.labelTransition(0.55)
                self.amountDenomLabel.labelTransition(0.35)
                self.feeAmountValueLabel.labelTransition(0.55)
                self.feeAmountDenomLabel.labelTransition(0.35)
                
                self.account = account
                self.selectedAsset = account?.assets.first
                self.denomPickerView.reloadAllComponents()
                
                if let validAccount = account {
                    self.amountValueLabel.text = "\(validAccount.amount)"
                    self.amountDenomLabel.text = validAccount.denom
                    if let feeDenom = validAccount.feeDenom, let feeAmount = validAccount.feeAmount {
                        self.feeAmountValueLabel.text = "\(feeAmount)"
                        self.feeAmountDenomLabel.text = feeDenom
                    }
                } else {
                    if let message = errMessage, message.count > 0 {
                        self.toast?.showToastAlert(errMessage, autoHideAfter: 5, type: .error, dismissable: true)
                    }
                    self.amountValueLabel.text = "0.00"
                    self.amountDenomLabel.text = "-"
                }
            }
        }
    }
    
    @objc
    func keyboardWillAppear(notification: NSNotification?) {
        
        guard view.frame.size.height <= 568 else { return }
        
        topConstraintOutlet.constant = -40
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }
    
    @objc
    func keyboardWillDisappear(notification: NSNotification?) {
        
        guard view.frame.size.height <= 568 else { return }
        
        topConstraintOutlet.constant = 26
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    
}

extension GaiaWalletController: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.selectedAsset = account?.assets[row]
        if let amount = Double(sendAmountTextField.text ?? "0"), let balanceStr = selectedAsset?.amount, let balance = Double(balanceStr) {
            self.sendAmountButton.isEnabled = amount <= balance
        }
    }
}

extension GaiaWalletController: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return account?.assets.count ?? 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return account?.assets[row].denom
    }
}

extension GaiaWalletController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        guard  !textField.isSecureTextEntry else { return true }
        
        let newString = NSString(string: textField.text!).replacingCharacters(in: range, with: string)
        if let amount = Double(newString), let balanceStr = selectedAsset?.amount, let balance = Double(balanceStr) {
            self.sendAmountButton.isEnabled = amount <= balance
        } else {
            self.sendAmountButton.isEnabled = false
        }
        return true
    }

}
