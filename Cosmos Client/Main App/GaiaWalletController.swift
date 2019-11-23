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
    
    var node: TDMNode?
    var key: GaiaKey?
    var keysDelegate: LocalClient?
    var account: GaiaAccount?
    var feeAmount: String { return node?.defaultTxFee  ?? "0" }

    var toast: ToastAlertView?
    
    let refreshInterval: TimeInterval = 10
    
    @IBOutlet weak var screenTitleLabel: UILabel!
    @IBOutlet weak var loadingView: CustomLoadingView!
    @IBOutlet weak var toastHolderUnderView: UIView!
    @IBOutlet weak var toastHolderTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var topNavBarView: UIView!
    @IBOutlet weak var bottomTabbarView: CustomTabBar!
    @IBOutlet weak var bottomTabbarDownConstraint: NSLayoutConstraint!
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var txFeeLabel: UILabel!
    @IBOutlet weak var accountTitleLabel: UILabel!
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
    private weak var timer: Timer?

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
        clearFields()
        if let validKey = key {
            qrTestImageView.image = UIImage.getQRCodeImage(from: validKey.address)
            accountTitleLabel.text = validKey.name
            addressLabel.text     = validKey.address
        }
        txFeeLabel.text = ""
        sendAmountButton.isEnabled = false
        screenTitleLabel.text = node?.network ?? "Wallet"
        
        let _ = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main) { [weak self] note in
            self?.clearFields()
            self?.node?.getStatus {
                if self?.node?.state == .unknown {
                    self?.performSegue(withIdentifier: "UnwindToNodes", sender: self)
                } else {
                    self?.loadData()
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        bottomTabbarView.selectIndex(0)
        
        if let addrToSend = senderAddress, let denom = selectedAsset?.denom {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                
                let amount = self?.sendAmountTextField.text ?? "0"
                let memo = self?.node?.defaultMemo ?? ""
                let alert = UIAlertController(title: "Send \(amount) \(denom) to \(addrToSend)", message: "Memo: \(memo)", preferredStyle: UIAlertController.Style.alert)
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] alertAction in
                    self?.sendAmountTextField.text = ""
                    self?.sendAmountButton.isEnabled = false
                    self?.loadingView.stopAnimating()
                    self?.senderAddress = nil
                }
                
                let action = UIAlertAction(title: "Confirm", style: .destructive) { [weak self] alertAction in
                    self?.loadingView.startAnimating()
                    self?.sendAssetsTo(destAddress: addrToSend, denom: denom)
                }
                
                alert.addAction(cancelAction)
                alert.addAction(action)
                
                self?.present(alert, animated:true, completion: nil)
            }

        } else {
            loadingView.startAnimating()
            self.loadData()
        }
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] timer in
            self?.loadData(animated: false, spinner: false)
        }
    }
    
    private func sendAssetsTo(destAddress: String, denom: String) {
        
        guard let node = node, let key = key, let keysDelegate = keysDelegate else { return }
        sendAssets(node: node,
                   clientDelegate: keysDelegate,
                   key: key,
                   feeAmount: feeAmount,
                   toAddress: destAddress,
                   amount: sendAmountTextField.text ?? "0",
                   denom: denom) { [weak self] response, error in
                    DispatchQueue.main.async {
                        
                        self?.sendAmountTextField.text = ""
                        self?.sendAmountButton.isEnabled = false
                        self?.loadingView.stopAnimating()
                        
                        if let validResponse = response {
                            self?.toast?.showToastAlert("[\(validResponse.hash ?? "...")] submited", autoHideAfter: 15, type: .validatePending, dismissable: false)
                        } else if let errMsg = error {
                            if errMsg.contains("connection was lost") {
                                self?.toast?.showToastAlert("Tx broadcasted but not confirmed yet", autoHideAfter: 5, type: .validatePending, dismissable: true)
                            } else {
                                self?.toast?.showToastAlert(errMsg, autoHideAfter: 15, type: .error, dismissable: true)
                            }
                        } else {
                            self?.toast?.showToastAlert("Ooops, I failed.", autoHideAfter: 15, type: .error, dismissable: true)
                        }
                    }
        }
        senderAddress = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification , object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification , object: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "ShowAddressBookSegue":
            let nav = segue.destination as? UINavigationController
            let dest = nav?.viewControllers.first as? AddressesListController
            dest?.shouldPop = true
            dest?.onSelectAddress = { [weak self] selected in
                if let validAddress = selected {
                    self?.senderAddress = validAddress.address
                }
            }

        case "HistorySegueID":
            let dest = segue.destination as? GaiaHistoryController
            dest?.node = node
            dest?.account = account
            dest?.key = key
            clearFields()
            
        case "nextSegue":
            clearFields()
            if let index = sender as? Int {
                let dest = segue.destination as? GaiaValidatorsController
                dest?.forwardCounter = index - 1
                dest?.node = node
                dest?.account = account
                dest?.key = key
                dest?.redelgateFrom = redelgateFrom
                dest?.keysDelegate = keysDelegate
                redelgateFrom = nil
            }
            
        default: clearFields()
        }
    }
    
    func clearFields() {
        amountValueLabel.text = ""
        amountDenomLabel.text = ""
        feeAmountValueLabel.text = ""
        feeAmountDenomLabel.text = ""
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
    
    private func queryRewards(validDelegations: [GaiaDelegation]) {
        guard let validNode = node else { return }
        for delegation in validDelegations {
            key?.queryDelegationRewards(node: validNode, validatorAddr: delegation.validatorAddr) { [weak self] rewards, err in
                if let amount = rewards {
                    if self?.account?.gaiaKey.validator == delegation.validatorAddr {
                        self?.key?.queryValidatorRewards(node: validNode, validator: delegation.validatorAddr) { [weak self] rewards, err in
                            if let total = rewards {
                                delegation.availableReward = total + amount > 0 ? "\(total + amount)💰" : ""
                                self?.tableView.reloadData()
                            }
                        }
                    } else {
                        delegation.availableReward = amount > 0 ? "\(amount)💰" : ""
                        self?.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    private func loadData(animated: Bool = true, spinner: Bool = true) {
        
        if animated {
            self.amountValueLabel.labelTransition(0.55)
            self.amountDenomLabel.labelTransition(0.35)
            self.feeAmountValueLabel.labelTransition(0.55)
            self.feeAmountDenomLabel.labelTransition(0.35)
        }
        
        if let validNode = node, let validKey = key {
            validKey.getGaiaAccount(node: validNode, gaiaKey: validKey) { [weak self] account, errMessage in
                
                validKey.getDelegations(node: validNode) { [weak self] delegations, error in
                    if let validDelegations = delegations {
                        self?.dataSource = validDelegations
                        self?.tableView.reloadData()
                        self?.queryRewards(validDelegations: validDelegations)
                    }
                }

                if spinner { self?.loadingView.stopAnimating() }
                
                self?.account = account
                if self?.selectedAsset == nil {
                    self?.selectedAsset = account?.assets.first
                }
                if let matches = account?.assets.filter({ $0.denom == self?.selectedAsset?.denom }) {
                    self?.selectedAsset = matches.first
                }
                self?.denomPickerView.reloadAllComponents()
                
                if let validAccount = account, let asset = self?.selectedAsset, let amount = asset.amount {
                    let finalVal = amount.split(separator: ".").first ?? "0"
                    self?.amountValueLabel.text = "\(finalVal)"
                    self?.amountDenomLabel.text = asset.denom
                    
                    self?.txFeeLabel.text = validAccount.firendlyAmountAndDenom(for: self?.node?.type ?? .cosmos)
                } else {
                    self?.txFeeLabel.text = "Default Fee: \(validNode.defaultTxFee)"
                    if let message = errMessage, message.count > 0 {
                        if message.contains("connection was lost") {
                            self?.toast?.showToastAlert("Tx broadcasted but not confirmed yet", autoHideAfter: 5, type: .validatePending, dismissable: true)
                        } else {
                            self?.toast?.showToastAlert(message, autoHideAfter: 15, type: .error, dismissable: true)
                        }
                    }
                    self?.amountValueLabel.text = "0.00"
                    self?.amountDenomLabel.text = "-"
                }
                
                let seq = account?.accSequence ?? "0"
                self?.feeAmountValueLabel.text = "" + seq
                self?.feeAmountDenomLabel.text = "sequence"
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
    
    func killZeroes(_ temp: Double) -> String {
        let tempVar = String(format: "%g", temp)
        return tempVar
    }
    
    private func handleDelegate(delegation: GaiaDelegation, denom: String) {
        
        showAmountAlert(title: "Type the amount of \(denom) you want to delegate to:", message: "\(delegation.validatorAddr)\nIt holds\n\(Double(delegation.shares) ?? 0) \(denom) from you.", placeholder: "0 \(denom)") { [weak self] amount in
            if let validAmount = amount, let validNode = self?.node, let validKey = self?.key, let delegate = self?.keysDelegate {
                self?.loadingView.startAnimating()
                self?.delegateStake(
                    node: validNode,
                    clientDelegate: delegate,
                    key: validKey,
                    feeAmount: self?.feeAmount ?? "0",
                    toValidator: delegation.validatorAddr,
                    amount: validAmount,
                    denom: denom) { (resp, err) in
                        if err == nil {
                            self?.toast?.showToastAlert("Delegation successfull", autoHideAfter: 5, type: .info, dismissable: true)
                            self?.key?.getDelegations(node: validNode) { [weak self] delegations, error in
                                self?.loadingView.stopAnimating()
                                if let validDelegations = delegations {
                                    self?.dataSource = validDelegations
                                    self?.tableView.reloadData()
                                    self?.queryRewards(validDelegations: validDelegations)
                                }
                            }
                        } else if let errMsg = err {
                            self?.loadingView.stopAnimating()
                            if errMsg.contains("connection was lost") {
                                self?.toast?.showToastAlert("Tx broadcasted but not confirmed yet", autoHideAfter: 5, type: .validatePending, dismissable: true)
                            } else {
                                self?.toast?.showToastAlert(errMsg, autoHideAfter: 15, type: .error, dismissable: true)
                            }
                        }
                }
            }
        }
    }
    
    private func handleUnbound(delegation: GaiaDelegation, denom: String) {
        
        self.showAmountAlert(title: "Type the amount of \(denom) you want to unbond", message: "\(delegation.validatorAddr) holds\n\(Int(delegation.shares) ?? 0) \(denom)", placeholder: "0 \(denom)") { [weak self] amount in
            if let validAmount = amount, let validNode = self?.node, let validKey = self?.key, let delegate = self?.keysDelegate {
                self?.loadingView.startAnimating()
                self?.unbondStake(node: validNode, clientDelegate: delegate, key: validKey, feeAmount: self?.feeAmount ?? "0", fromValidator: delegation.validatorAddr, amount: validAmount, denom: denom) { (resp, err) in
                    if err == nil {
                        self?.toast?.showToastAlert("Unbonding successfull", autoHideAfter: 15, type: .info, dismissable: true)
                        self?.key?.getDelegations(node: validNode) { [weak self] delegations, error in
                            self?.loadingView.stopAnimating()
                            if let validDelegations = delegations {
                                self?.dataSource = validDelegations
                                self?.tableView.reloadData()
                                self?.queryRewards(validDelegations: validDelegations)
                            }
                        }
                    } else if let errMsg = err {
                        self?.loadingView.stopAnimating()
                        if errMsg.contains("connection was lost") {
                            self?.toast?.showToastAlert("Tx broadcasted but not confirmed yet", autoHideAfter: 5, type: .validatePending, dismissable: true)
                        } else {
                            self?.toast?.showToastAlert(errMsg, autoHideAfter: 15, type: .error, dismissable: true)
                        }
                    }
                }
            }
        }
    }
    
    private func handleWithdraw(delegation: GaiaDelegation) {
        
        if let validNode = node, let validKey = key, let keysDelegate = keysDelegate {
            loadingView.startAnimating()
            withdraw(node: validNode, clientDelegate: keysDelegate, key: validKey, feeAmount: feeAmount, validator: delegation.validatorAddr) { [weak self] resp, err in
                if err == nil {
                    self?.toast?.showToastAlert("Withdraw successfull", autoHideAfter: 15, type: .info, dismissable: true)
                    self?.key?.getDelegations(node: validNode) { [weak self] delegations, error in
                        self?.loadingView.stopAnimating()
                        if let validDelegations = delegations {
                            self?.dataSource = validDelegations
                            self?.tableView.reloadData()
                            self?.queryRewards(validDelegations: validDelegations)
                        }
                    }
                } else if let errMsg = err {
                    self?.loadingView.stopAnimating()
                    if errMsg.contains("connection was lost") {
                        self?.toast?.showToastAlert("Tx broadcasted but not confirmed yet", autoHideAfter: 5, type: .validatePending, dismissable: true)
                    } else {
                        self?.toast?.showToastAlert(errMsg, autoHideAfter: 15, type: .error, dismissable: true)
                    }
                }
            }
        }
    }
    
    private func handleWithdrawComission(delegation: GaiaDelegation) {
        
        if let validNode = node, let validKey = key, let keysDelegate = keysDelegate {
            loadingView.startAnimating()
            withdrawComission(node: validNode, clientDelegate: keysDelegate, key: validKey, feeAmount: feeAmount) { [weak self] resp, err in
                if err == nil {
                    self?.toast?.showToastAlert("Comission withdraw successfull", autoHideAfter: 15, type: .info, dismissable: true)
                    self?.key?.getDelegations(node: validNode) { [weak self] delegations, error in
                        self?.loadingView.stopAnimating()
                        if let validDelegations = delegations {
                            self?.dataSource = validDelegations
                            self?.tableView.reloadData()
                            self?.queryRewards(validDelegations: validDelegations)
                        }
                    }
                } else if let errMsg = err {
                    self?.loadingView.stopAnimating()
                    if errMsg.contains("connection was lost") {
                        self?.toast?.showToastAlert("Tx broadcasted but not confirmed yet", autoHideAfter: 5, type: .validatePending, dismissable: true)
                    } else {
                        self?.toast?.showToastAlert(errMsg, autoHideAfter: 15, type: .error, dismissable: true)
                    }
                }
            }
        }
    }
}

extension GaiaWalletController: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.selectedAsset = account?.assets[row]
        self.amountValueLabel.text = self.selectedAsset?.amount
        self.amountDenomLabel.text = self.selectedAsset?.denom

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
        if let amount = Double(newString) {
            self.sendAmountButton.isEnabled = amount >= 0
        } else {
            self.sendAmountButton.isEnabled = false
        }
        return true
    }
    
}

extension GaiaWalletController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 11
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GaiaKeyCell", for: indexPath) as! GaiaKeyCell
        let delegation = dataSource[indexPath.item]
        let parts = delegation.shares.split(separator: ".")
        let validatorName = node?.knownValidators[delegation.validatorAddr] ?? ""
        cell.leftLabel.text = "\(parts.first ?? "0") shares to " + validatorName
        cell.leftSubLabel.text = delegation.validatorAddr
        cell.leftLabel.textColor = .darktext
        cell.upRightLabel?.text = delegation.availableReward
        if account?.gaiaKey.validator == delegation.validatorAddr {
            cell.leftLabel.textColor = .darkBlue
            account?.isValidator = true
        }
        return cell
    }
}

extension GaiaWalletController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let delegation = dataSource[indexPath.item]
        
        DispatchQueue.main.async {
            
            if let validDenom = self.node?.stakeDenom {
                
                let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                
                if delegation.validatorAddr == self.account?.gaiaKey.validator {
                    let withdrawCommissionAction = UIAlertAction(title: "Withdraw commissions", style: .default) { [weak self] alertAction in
                        self?.handleWithdrawComission(delegation: delegation)
                    }
                    optionMenu.addAction(withdrawCommissionAction)
                }
                let withdrawAction = UIAlertAction(title: "Withdraw rewards", style: .default) { [weak self] alertAction in
                    self?.handleWithdraw(delegation: delegation)
                }
                let delegateAction = UIAlertAction(title: "Delegate", style: .default) { [weak self] alertAction in
                    self?.handleDelegate(delegation: delegation, denom: validDenom)
                }
                
                let unboundAction = UIAlertAction(title: "Unbond", style: .default) { [weak self] alertAction in
                    self?.handleUnbound(delegation: delegation, denom: validDenom)
                }
                
                let redelegateAction = UIAlertAction(title: "Redelegate", style: .default) { [weak self] alertAction in
                    self?.redelgateFrom = delegation.validatorAddr
                    self?.performSegue(withIdentifier: "nextSegue", sender: 1)
                }
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                
                optionMenu.addAction(withdrawAction)
                optionMenu.addAction(redelegateAction)
                optionMenu.addAction(delegateAction)
                optionMenu.addAction(unboundAction)
                optionMenu.addAction(cancelAction)
                
                self.present(optionMenu, animated: true, completion: nil)
            }
        }
    }
}
