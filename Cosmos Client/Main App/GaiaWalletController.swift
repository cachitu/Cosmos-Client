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
    
    var defaultFeeSigAmount: String { return AppContext.shared.node?.defaultTxFee  ?? "0" }

    var toast: ToastAlertView?
    
    @IBOutlet weak var historyButton: UIButton!
    @IBOutlet weak var screenTitleLabel: UILabel!
    @IBOutlet weak var loadingView: CustomLoadingView!
    @IBOutlet weak var toastHolderUnderView: UIView!
    @IBOutlet weak var toastHolderTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var topNavBarView: UIView!
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
    @IBOutlet weak var swapButton: RoundedButton!
    
    @IBOutlet weak var amoutRoundedView: RoundedView?
    @IBOutlet weak var currencyPickerRoundedView: RoundedView!
    
    @IBOutlet weak var qrTestImageView: UIImageView!
    @IBAction func backAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBOutlet weak var topConstraintOutlet: NSLayoutConstraint!
    @IBOutlet weak var coinLogoImageView: UIImageView!
    
    @IBOutlet weak var logsButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var logsButton: RoundedButton!
    @IBAction func logsAction(_ sender: UIButton) {
    }
    
    private var selectedAsset: Coin?
    private var senderAddress: String?
    private weak var timer: Timer?

    var dataSource: [GaiaDelegation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toast = createToastAlert(creatorView: view, holderUnderView: toastHolderUnderView, holderTopDistanceConstraint: toastHolderTopConstraint, coveringView: topNavBarView)
        coinLogoImageView.image = AppContext.shared.node?.nodeLogoWhite
        clearFields()
        if let validKey = AppContext.shared.key {
            qrTestImageView.image = UIImage.getQRCodeImage(from: validKey.address)
            accountTitleLabel.text = validKey.name
            addressLabel.text     = validKey.address
        }
        txFeeLabel.text = ""
        sendAmountButton.isEnabled = false
        sendAmountTextField.isEnabled = AppContext.shared.key?.watchMode != true
        
        amoutRoundedView?.alpha = AppContext.shared.key?.watchMode == true ? 0.8 : 1.0
        currencyPickerRoundedView?.alpha = amoutRoundedView?.alpha ?? 1.0

        screenTitleLabel.text = AppContext.shared.node?.network ?? "Wallet"
        swapButton.isHidden = !(AppContext.shared.node?.type == TDMNodeType.terra || AppContext.shared.node?.type == TDMNodeType.terra_118)
        historyButton.isHidden = (AppContext.shared.node?.type == TDMNodeType.iris || AppContext.shared.node?.type == TDMNodeType.iris_fuxi)
        let _ = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main) { [weak self] note in
            self?.clearFields()
            AppContext.shared.node?.getStatus {
                if AppContext.shared.node?.state == .unknown {
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
        if senderAddress == nil {
             clearFields()
        }
        
        if AppContext.shared.key?.watchMode == true {
            logsButtonBottomConstraint.constant = -50
        } else {
            AppContext.shared.onHashPolingPending = {
                self.logsButton.backgroundColor = UIColor.pendingYellow
            }
            AppContext.shared.onHashPolingDone = {
                self.logsButton.backgroundColor = UIColor.darkRed
            }
            if let hash = AppContext.shared.lastSubmitedHash() {
                AppContext.shared.startHashPoling(hash: hash)
            } else {
                self.logsButton.backgroundColor = UIColor.darkRed
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let addrToSend = senderAddress, let denom = selectedAsset?.denom {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                
                let amount = self?.sendAmountTextField.text ?? "0"
                let memo = AppContext.shared.node?.defaultMemo ?? ""
                //let adjusetdDenom = denom == "iris-atto" ? "iris" : denom
                let alert = UIAlertController(title: "Send \(amount) \(denom) to \(addrToSend)", message: "Memo: \(memo)", preferredStyle: UIAlertController.Style.alert)
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] alertAction in
                    self?.sendAmountTextField.text = ""
                    self?.sendAmountButton.isEnabled = false
                    self?.loadingView.stopAnimating()
                    self?.senderAddress = nil
                }
                
                let action = UIAlertAction(title: "Confirm", style: .destructive) { [weak self] alertAction in
                    self?.loadingView.startAnimating()
                    self?.toast?.hideToast()
                    self?.sendAssetsTo(destAddress: addrToSend, denom: denom)
                }
                
                alert.addAction(cancelAction)
                alert.addAction(action)
                
                self?.present(alert, animated:true, completion: nil)
            }

        } else {
            loadingView.startAnimating()
            toast?.hideToast()
            clearFields()
            loadData()
        }
        timer = Timer.scheduledTimer(withTimeInterval: GaiaConstants.refreshInterval, repeats: true) { [weak self] timer in
            self?.loadData(animated: false, spinner: false)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification , object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification , object: nil)
        if !lockClearFields {
            clearFields()
        }
        lockClearFields = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        toast?.hideToast()
    }
    
    private func sendAssetsTo(destAddress: String, denom: String) {
        
        guard let node = AppContext.shared.node, let key = AppContext.shared.key, let keysDelegate = AppContext.shared.keysDelegate else { return }
        sendAssets(node: node,
                   clientDelegate: keysDelegate,
                   key: key,
                   feeAmount: defaultFeeSigAmount,
                   toAddress: destAddress,
                   amount: sendAmountTextField.text ?? "0",
                   denom: denom) { [weak self] resp, msg in
                    DispatchQueue.main.async {
                        
                        self?.sendAmountTextField.text = ""
                        self?.sendAmountButton.isEnabled = false
                        self?.loadingView.stopAnimating()
                        
                        if resp != nil {
                            self?.toast?.showToastAlert("Transfer submitted\n[\(msg ?? "...")] ", autoHideAfter: GaiaConstants.autoHideToastTime, type: .validatePending, dismissable: false)
                            if let hash = AppContext.shared.lastSubmitedHash() {
                                AppContext.shared.startHashPoling(hash: hash)
                            }
                        } else if let errMsg = msg {
                            if errMsg.contains("connection was lost") {
                                self?.toast?.showToastAlert("Tx broadcasted but not confirmed yet", autoHideAfter: GaiaConstants.autoHideToastTime, type: .validatePending, dismissable: true)
                            } else {
                                self?.toast?.showToastAlert(errMsg, autoHideAfter: GaiaConstants.autoHideToastTime, type: .error, dismissable: true)
                            }
                        } else {
                            self?.toast?.showToastAlert("Ooops, I failed.", autoHideAfter: GaiaConstants.autoHideToastTime, type: .error, dismissable: true)
                        }
                    }
        }
        senderAddress = nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {

        case "ShowAddressBookSegue":
            let nav = segue.destination as? UINavigationController
            let dest = nav?.viewControllers.first as? AddressesListController
            dest?.shouldPop = true
            dest?.addressPrefix = AppContext.shared.node?.adddressPrefix ?? ""
            
            dest?.onSelectAddress = { [weak self] selected in
                if let validAddress = selected {
                    self?.senderAddress = validAddress.address
                }
            }

        default: break
        }
    }
    
    func clearFields() {
        amountValueLabel.text = ""
        amountDenomLabel.text = ""
        feeAmountValueLabel.text = ""
        feeAmountDenomLabel.text = ""
    }
    
    @IBAction func shareAddress(_ sender: Any) {
        
        let text = AppContext.shared.key?.address ?? ""
        let textShare = [ text ]
        let activityViewController = UIActivityViewController(activityItems: textShare , applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func unwindToWallet(segue:UIStoryboardSegue) {
    }
    
    var lockClearFields = false
    @IBAction func sendAction(_ sender: Any) {
        
        lockClearFields = true
        self.performSegue(withIdentifier: "ShowAddressBookSegue", sender: self)
    }
    
    private func queryRewards(validDelegations: [GaiaDelegation]) {
        guard let validNode = AppContext.shared.node else { return }
        for delegation in validDelegations {
            AppContext.shared.key?.queryDelegationRewards(node: validNode, validatorAddr: delegation.validatorAddr) { [weak self] rewards, err in
                if let amount = rewards {
                    if AppContext.shared.account?.gaiaKey.validator == delegation.validatorAddr {
                        AppContext.shared.key?.queryValidatorRewards(node: validNode, validator: delegation.validatorAddr) { [weak self] rewards, err in
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
        
        if let hash = AppContext.shared.lastSubmitedHash() {
            AppContext.shared.startHashPoling(hash: hash)
        }
        
        if animated {
            self.amountValueLabel.labelTransition(0.55)
            self.amountDenomLabel.labelTransition(0.35)
            self.feeAmountValueLabel.labelTransition(0.55)
            self.feeAmountDenomLabel.labelTransition(0.35)
        }
        
        if let validNode = AppContext.shared.node, let validKey = AppContext.shared.key {
            
            validKey.getGaiaAccount(node: validNode, gaiaKey: validKey) { [weak self] account, errMessage in
                
                validKey.getDelegations(node: validNode) { [weak self] delegations, error in
                    if let validDelegations = delegations {
                        self?.dataSource = validDelegations
                        self?.tableView.reloadData()
                        self?.queryRewards(validDelegations: validDelegations)
                    }
                }

                if spinner { self?.loadingView.stopAnimating() }
                
                AppContext.shared.account = account
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
                    
                    self?.txFeeLabel.text = validAccount.firendlyAmountAndDenom(for: AppContext.shared.node?.type ?? .cosmos)
                } else {
                    self?.txFeeLabel.text = "Default Fee: \(validNode.defaultTxFee)"
                    if let message = errMessage, message.count > 0 {
                        if message.contains("connection was lost") {
                            self?.toast?.showToastAlert("Tx broadcasted but not confirmed yet", autoHideAfter: GaiaConstants.autoHideToastTime, type: .validatePending, dismissable: true)
                        } else {
                            self?.toast?.showToastAlert(message, autoHideAfter: GaiaConstants.autoHideToastTime, type: .error, dismissable: true)
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
            if let validAmount = amount, let validNode = AppContext.shared.node, let validKey = AppContext.shared.key, let delegate = AppContext.shared.keysDelegate {
                self?.loadingView.startAnimating()
                self?.toast?.hideToast()
                self?.delegateStake(
                    node: validNode,
                    clientDelegate: delegate,
                    key: validKey,
                    feeAmount: self?.defaultFeeSigAmount ?? "0",
                    toValidator: delegation.validatorAddr,
                    amount: validAmount,
                    denom: denom) { resp, msg in
                        if resp != nil {
                            self?.toast?.showToastAlert("Delegation submitted\n[\(msg ?? "...")]", autoHideAfter: GaiaConstants.autoHideToastTime, type: .validatePending, dismissable: true)
                            self?.loadData()
                        } else if let errMsg = msg {
                            self?.loadingView.stopAnimating()
                            if errMsg.contains("connection was lost") {
                                self?.toast?.showToastAlert("Tx broadcasted but not confirmed yet", autoHideAfter: GaiaConstants.autoHideToastTime, type: .validatePending, dismissable: true)
                            } else {
                                self?.toast?.showToastAlert(errMsg, autoHideAfter: GaiaConstants.autoHideToastTime, type: .error, dismissable: true)
                            }
                        }
                }
            }
        }
    }
    
    private func handleUnbound(delegation: GaiaDelegation, denom: String) {
        
        self.showAmountAlert(title: "Type the amount of \(denom) you want to unbond", message: "\(delegation.validatorAddr) holds\n\(Int(delegation.shares) ?? 0) \(denom)", placeholder: "0 \(denom)") { [weak self] amount in
            if let validAmount = amount, let validNode = AppContext.shared.node, let validKey = AppContext.shared.key, let delegate = AppContext.shared.keysDelegate {
                self?.loadingView.startAnimating()
                self?.toast?.hideToast()
                self?.unbondStake(node: validNode, clientDelegate: delegate, key: validKey, feeAmount: self?.defaultFeeSigAmount ?? "0", fromValidator: delegation.validatorAddr, amount: validAmount, denom: denom) { resp, msg in
                    if resp != nil {
                        self?.toast?.showToastAlert("Unbonding submitted\n[\(msg ?? "...")]", autoHideAfter: GaiaConstants.autoHideToastTime, type: .validatePending, dismissable: true)
                        self?.loadData()
                    } else if let errMsg = msg {
                        self?.loadingView.stopAnimating()
                        if errMsg.contains("connection was lost") {
                            self?.toast?.showToastAlert("Tx broadcasted but not confirmed yet", autoHideAfter: GaiaConstants.autoHideToastTime, type: .validatePending, dismissable: true)
                        } else {
                            self?.toast?.showToastAlert(errMsg, autoHideAfter: GaiaConstants.autoHideToastTime, type: .error, dismissable: true)
                        }
                    }
                }
            }
        }
    }
    
    private func handleWithdraw(delegation: GaiaDelegation) {
        
        if let validNode = AppContext.shared.node, let validKey = AppContext.shared.key, let keysDelegate = AppContext.shared.keysDelegate {
            loadingView.startAnimating()
            toast?.hideToast()
            withdraw(node: validNode, clientDelegate: keysDelegate, key: validKey, feeAmount: defaultFeeSigAmount, validator: delegation.validatorAddr) { [weak self] resp, msg in
                if resp != nil {
                    self?.toast?.showToastAlert("Withdraw submitted\n[\(msg ?? "...")]", autoHideAfter: GaiaConstants.autoHideToastTime, type: .validatePending, dismissable: true)
                    self?.loadData()
                } else if let errMsg = msg {
                    self?.loadingView.stopAnimating()
                    if errMsg.contains("connection was lost") {
                        self?.toast?.showToastAlert("Tx broadcasted but not confirmed yet", autoHideAfter: GaiaConstants.autoHideToastTime, type: .validatePending, dismissable: true)
                    } else {
                        self?.toast?.showToastAlert(errMsg, autoHideAfter: GaiaConstants.autoHideToastTime, type: .error, dismissable: true)
                    }
                }
            }
        }
    }
    
    private func handleWithdrawComission(delegation: GaiaDelegation) {
        
        if let validNode = AppContext.shared.node, let validKey = AppContext.shared.key, let keysDelegate = AppContext.shared.keysDelegate {
            loadingView.startAnimating()
            toast?.hideToast()
            withdrawComission(node: validNode, clientDelegate: keysDelegate, key: validKey, feeAmount: defaultFeeSigAmount) { [weak self] resp, msg in
                if resp != nil {
                    self?.toast?.showToastAlert("Comission withdraw submitted\n[\(msg ?? "...")]", autoHideAfter: GaiaConstants.autoHideToastTime, type: .validatePending, dismissable: true)
                    self?.loadData()
                } else if let errMsg = msg {
                    self?.loadingView.stopAnimating()
                    if errMsg.contains("connection was lost") {
                        self?.toast?.showToastAlert("Tx broadcasted but not confirmed yet", autoHideAfter: GaiaConstants.autoHideToastTime, type: .validatePending, dismissable: true)
                    } else {
                        self?.toast?.showToastAlert(errMsg, autoHideAfter: GaiaConstants.autoHideToastTime, type: .error, dismissable: true)
                    }
                }
            }
        }
    }
}

extension GaiaWalletController: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard AppContext.shared.account?.assets.count ?? 0 > row else { return }

        self.selectedAsset = AppContext.shared.account?.assets[row]
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
        return AppContext.shared.account?.assets.count ?? 0
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let string = AppContext.shared.account?.assets[row].denom ?? ""
        return NSAttributedString(string: string, attributes: [NSAttributedString.Key.foregroundColor : UIColor.darkGrayText])
    }
    
//    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        return AppContext.shared.account?.assets[row].denom
//    }
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
        return 6
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GaiaSharesCellID", for: indexPath) as! GaiaSharesCell
        let delegation = dataSource[indexPath.item]
        let validatorName = AppContext.shared.node?.knownValidators[delegation.validatorAddr] ?? ""
        
        cell.configure(key: AppContext.shared.key, delegation: delegation, validatorName: validatorName)
        
        if AppContext.shared.account?.gaiaKey.validator == delegation.validatorAddr {
            cell.leftLabel?.textColor = .pendingYellow
            AppContext.shared.account?.isValidator = true
        }
        return cell
    }
}

extension GaiaWalletController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let delegation = dataSource[indexPath.item]
        
        DispatchQueue.main.async {
            
            guard AppContext.shared.key?.watchMode != true else {
                self.toast?.showToastAlert("This account is read only", autoHideAfter: GaiaConstants.autoHideToastTime, type: .info, dismissable: true)
                return
            }
            
            if let validDenom = AppContext.shared.node?.stakeDenom {
                
                let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                
                if delegation.validatorAddr == AppContext.shared.account?.gaiaKey.validator {
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
                    AppContext.shared.redelgateFrom = delegation.validatorAddr
                    self?.tabBarController?.selectedIndex = 1
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
