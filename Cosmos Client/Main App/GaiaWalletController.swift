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
    var feeAmount: String = "0" //this is by default in fee denom, can't send in stake denom for now
    
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
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var qrTestImageView: UIImageView!
    @IBAction func backAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBOutlet weak var topConstraintOutlet: NSLayoutConstraint!

    private var selectedAsset: Coin?
    private var senderAddress: String?
    private var redelgateFrom: String?

    var dataSource: [GaiaDelegation] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        toast = createToastAlert(creatorView: view, holderUnderView: toastHolderUnderView, holderTopDistanceConstraint: toastHolderTopConstraint, coveringView: topNavBarView)
        bottomTabbarView.selectIndex(0)
        bottomTabbarView.onTap = { [weak self] index in
            switch index {
            case 1:
                self?.performSegue(withIdentifier: "nextSegue", sender: index)
            case 2:
                self?.performSegue(withIdentifier: "nextSegue", sender: index)
                UIView.setAnimationsEnabled(false)
            case 3:
                self?.performSegue(withIdentifier: "nextSegue", sender: index)
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
        
        guard let node = node, let key = key else { return }
        
        bottomTabbarView.selectIndex(0)
        
        key.getDelegations(node: node) { [weak self] delegations, error in
            if let validDelegations = delegations {
                self?.dataSource = validDelegations
                self?.tableView.reloadData()
            }
        }
        
        if let addrToSend = senderAddress, let denom = selectedAsset?.denom {
            sendAssets(node: node,
                       key: key,
                       feeAmount: feeAmount,
                       toAddress: addrToSend,
                       amount: sendAmountTextField.text ?? "0",
                       denom: denom) { [weak self] response, error in
                        DispatchQueue.main.async {
                            
                            self?.sendAmountTextField.text = ""
                            self?.sendAmountButton.isEnabled = false

                            if let validResponse = response {
                                self?.toast?.showToastAlert("[\(validResponse.hash ?? "...")] submited", autoHideAfter: 5, type: .validatePending, dismissable: false)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                    self?.loadData(animated: false)
                                }
                            } else if let errMsg = error {
                                self?.loadingView.stopAnimating()
                                self?.toast?.showToastAlert(errMsg, autoHideAfter: 5, type: .error, dismissable: true)
                            } else {
                                self?.loadingView.stopAnimating()
                                self?.toast?.showToastAlert("Ooops, I failed.", autoHideAfter: 5, type: .error, dismissable: true)
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
            dest?.onSelectAddress = { [weak self] selected in
                if let validAddress = selected {
                    self?.senderAddress = validAddress.address
                }
            }
        }
        if segue.identifier == "nextSegue" {
            amountValueLabel.text = ""
            amountDenomLabel.text = ""
            feeAmountValueLabel.text = ""
            feeAmountDenomLabel.text = ""
            if let index = sender as? Int {
                let dest = segue.destination as? GaiaValidatorsController
                dest?.forwardCounter = index - 1
                dest?.node = node
                dest?.account = account
                dest?.key = key
                dest?.redelgateFrom = redelgateFrom
                dest?.feeAmount = feeAmount
                redelgateFrom = nil
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
    
    private func loadData(animated: Bool = true) {
        
        if let validNode = node, let validKey = key {
            getAccount(node: validNode, key: validKey) { [weak self] account, errMessage in
                
                self?.loadingView.stopAnimating()
                if animated {
                    self?.amountValueLabel.labelTransition(0.55)
                    self?.amountDenomLabel.labelTransition(0.35)
                    self?.feeAmountValueLabel.labelTransition(0.55)
                    self?.feeAmountDenomLabel.labelTransition(0.35)
                }
                
                self?.account = account
                if self?.selectedAsset == nil {
                    self?.selectedAsset = account?.assets.first
                }
                if account?.assets.count == 1 {
                    self?.selectedAsset = account?.assets.first
                }
                self?.denomPickerView.reloadAllComponents()
                
                if let validAccount = account {
                    self?.amountValueLabel.text = "\(validAccount.amount)"
                    self?.amountDenomLabel.text = validAccount.denom
                    if let feeDenom = validAccount.feeDenom, let feeAmount = validAccount.feeAmount {
                        self?.feeAmountValueLabel.text = "\(feeAmount)"
                        self?.feeAmountDenomLabel.text = feeDenom
                    } else {
                        self?.feeAmountValueLabel.text = ""
                        self?.feeAmountDenomLabel.text = ""
                    }
                } else {
                    if let message = errMessage, message.count > 0 {
                        self?.toast?.showToastAlert(errMessage, autoHideAfter: 5, type: .error, dismissable: true)
                    }
                    self?.amountValueLabel.text = "0.00"
                    self?.amountDenomLabel.text = "-"
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

extension GaiaWalletController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GaiaKeyCellID", for: indexPath) as! GaiaKeyCell
        let delegation = dataSource[indexPath.item]
        let intShares = Double(delegation.shares) ?? 0
        cell.leftLabel.text = "\(intShares) shares delegated to:"
        cell.leftSubLabel.text = delegation.validatorAddr
        return cell
    }
    
}

extension GaiaWalletController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let delegation = dataSource[indexPath.item]
        node?.getStakingInfo() { [weak self] denom in
            
            if let validDenom = denom {
                
                let optionMenu = UIAlertController(title: nil, message: "Choose Option", preferredStyle: .actionSheet)
                let delegateAction = UIAlertAction(title: "Delegate", style: .default) { alertAction in
                    self?.showAmountAlert(title: "Type the amount of \(validDenom) you want to delegate to:", message: "\(delegation.validatorAddr)\nIt holds\n\(Double(delegation.shares) ?? 0) \(validDenom) from you.", placeholder: "0 \(validDenom)") { amount in
                        if let validAmount = amount, let validNode = self?.node, let validKey = self?.key {
                            self?.loadingView.startAnimating()
                            self?.delegateStake(node: validNode,
                                                key: validKey,
                                                feeAmount: self?.feeAmount ?? "0",
                                                toValidator: delegation.validatorAddr,
                                                amount: validAmount,
                                                denom: validDenom) { (resp, err) in
                                                    if err == nil {
                                                        self?.toast?.showToastAlert("Delegation successfull", autoHideAfter: 5, type: .info, dismissable: true)
                                                        self?.key?.getDelegations(node: validNode) { [weak self] delegations, error in
                                                            self?.loadingView.stopAnimating()
                                                            if let validDelegations = delegations {
                                                                self?.dataSource = validDelegations
                                                                self?.tableView.reloadData()
                                                            }
                                                        }
                                                    } else if let errMsg = err {
                                                        self?.loadingView.stopAnimating()
                                                        self?.toast?.showToastAlert(errMsg, autoHideAfter: 5, type: .error, dismissable: true)
                                                    }
                                                    
                            }
                        }
                    }
                }
                
                let unboundAction = UIAlertAction(title: "Unbond", style: .default) { alertAction in
                    self?.showAmountAlert(title: "Type the amount of \(validDenom) you want to unbond", message: "\(delegation.validatorAddr) holds\n\(Int(delegation.shares) ?? 0) \(validDenom)", placeholder: "0 \(validDenom)") { amount in
                        if let validAmount = amount, let validNode = self?.node, let validKey = self?.key {
                            self?.loadingView.startAnimating()
                            self?.unbondStake(node: validNode, key: validKey, feeAmount: self?.feeAmount ?? "0", fromValidator: delegation.validatorAddr, amount: validAmount, denom: validDenom) { (resp, err) in
                                if err == nil {
                                    self?.toast?.showToastAlert("Unbonding successfull", autoHideAfter: 5, type: .info, dismissable: true)
                                    self?.key?.getDelegations(node: validNode) { [weak self] delegations, error in
                                        self?.loadingView.stopAnimating()
                                        if let validDelegations = delegations {
                                            self?.dataSource = validDelegations
                                            self?.tableView.reloadData()
                                        }
                                    }
                                } else if let errMsg = err {
                                    self?.loadingView.stopAnimating()
                                    self?.toast?.showToastAlert(errMsg, autoHideAfter: 5, type: .error, dismissable: true)
                                }
                            }
                        }
                    }
                }
                
                let redelegateAction = UIAlertAction(title: "Redelegate", style: .default) { alertAction in
                    self?.redelgateFrom = delegation.validatorAddr
                    self?.performSegue(withIdentifier: "nextSegue", sender: 1)
                }
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                
                optionMenu.addAction(delegateAction)
                optionMenu.addAction(unboundAction)
                optionMenu.addAction(redelegateAction)
                optionMenu.addAction(cancelAction)
                
                self?.present(optionMenu, animated: true, completion: nil)

            }
        }
    }
}
