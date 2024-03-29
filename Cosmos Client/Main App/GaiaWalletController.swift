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
    
    var defaultFeeSigAmount: String { return AppContext.shared.node?.feeAmount  ?? "0" }

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
    @IBOutlet weak var sendAmountButton: RoundedButton!
    @IBOutlet weak var denomPickerView: UIPickerView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var swapButton: RoundedButton!
    
    @IBOutlet weak var amoutRoundedView: RoundedView?
    @IBOutlet weak var currencyPickerRoundedView: RoundedView!
    
    @IBOutlet weak var topConstraintOutlet: NSLayoutConstraint!
    @IBOutlet weak var coinLogoImageView: UIImageView!
    
    @IBOutlet weak var logsButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var logsButton: RoundedButton!
    
    @IBOutlet weak var qrVisualBackground: UIVisualEffectView!
    @IBOutlet weak var qrTestImageView: UIImageView!
    @IBOutlet weak var qrShareButton: UIButton!
    @IBOutlet weak var qrCloseButton: UIButton!
    @IBOutlet weak var qrImageBottomCenterYConstraint: NSLayoutConstraint!
    
    @IBAction func qrCloseAction(_ sender: UIButton) {
        updateQR(visible: false)
    }
    
    @IBAction func qrShowAction(_ sender: UIButton) {
        updateQR(visible: true)
    }
    
    func updateQR(visible: Bool) {
        let alpha: CGFloat = visible ? 1.0 : 0.0
        qrTestImageView.alpha = 1
        qrImageBottomCenterYConstraint.constant = visible ? 0 : 1000
        UIView.animate(withDuration: 0.5,
                       delay: 0.0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 2,
                       options: [.curveEaseInOut],
                       animations: { [weak self] in
                        self?.qrVisualBackground.isHidden = alpha < 1
                        self?.qrShareButton.alpha = alpha
                        self?.qrCloseButton.alpha = alpha
                        self?.view.layoutIfNeeded()
        }) { [weak self] success in
            self?.qrTestImageView.alpha = alpha
        }
    }

    
    @IBAction func backAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func logsAction(_ sender: UIButton) {
    }
    
    @IBAction func shareAddress(_ sender: Any) {
        
        let text = AppContext.shared.key?.address ?? ""
        let textShare = [ text ]
        let activityViewController = UIActivityViewController(activityItems: textShare , applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @IBAction func sendAction(_ sender: Any) {
        
        lockClearFields = true
        self.performSegue(withIdentifier: "ShowAddressBookSegue", sender: self)
    }
    
    @IBAction func unwindToWallet(segue:UIStoryboardSegue) {
    }
    

    private var selectedAsset: Coin?
    private var senderAddress: String? {
        didSet {
            if let addrToSend = senderAddress, let denom = selectedAsset?.denom {
                senderAddress = nil
                if let tabBar = tabBarController as? GaiaTabBarController {
                    AppContext.shared.collectForStaking = false
                    AppContext.shared.collectMaxAmount = nil
                    AppContext.shared.collectAsset = selectedAsset
                    tabBar.promptForAmount()
                    AppContext.shared.collectSummary = [
                        "Send \(denom)",
                        "From:\n\(AppContext.shared.key?.address ?? "you")",
                        "To:\n\(addrToSend)"]

                    tabBar.onCollectAmountConfirm = { [weak self] in
                        tabBar.onCollectAmountConfirm = nil
                        if AppContext.shared.node?.securedSigning == true, let tabBar = self?.tabBarController as? GaiaTabBarController {
                            tabBar.onSecurityCheck = { [weak self] succes in
                                tabBar.onSecurityCheck = nil
                                if succes {
                                    self?.loadingView.startAnimating()
                                    self?.toast?.hideToast()
                                    self?.sendAssetsTo(destAddress: addrToSend, denom: denom)
                                } else {
                                    self?.senderAddress = nil
                                    self?.toast?.showToastAlert("The pin you entered is incorrect. Please try again.",  type: .error, dismissable: true)
                                }
                            }
                            tabBar.promptForPin(mode: .sign)
                        } else {
                            self?.loadingView.startAnimating()
                            self?.toast?.hideToast()
                            self?.sendAssetsTo(destAddress: addrToSend, denom: denom)
                        }
                    }
                }
            }
        }
    }
    
    private weak var timer: Timer?

    var lockClearFields = false
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
        
        amoutRoundedView?.backgroundColor = AppContext.shared.key?.watchMode == true ? .cellBackgroundColorAlpha : .cellBackgroundColor
        currencyPickerRoundedView?.backgroundColor = amoutRoundedView?.backgroundColor

        screenTitleLabel.text = AppContext.shared.node?.network ?? "Wallet"
        swapButton.isHidden = true//!(AppContext.shared.node?.type == TDMNodeType.terra || AppContext.shared.node?.type == TDMNodeType.terra_118) || AppContext.shared.key?.watchMode == true || AppContext.shared.account?.isEmpty == true
        historyButton.isHidden = false
        let _ = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main) { [weak self] note in
            guard !AppContext.shared.collectScreenOpen else { return }
            self?.clearFields()
            AppContext.shared.node?.getStatus {
                if AppContext.shared.node?.state == .unknown {
                    self?.performSegue(withIdentifier: "UnwindToNodes", sender: self)
                } else {
                    self?.loadData()
                }
            }
        }
        
        denomPickerView.layer.borderColor = UIColor(white: 0.5, alpha: 0.2).cgColor
        denomPickerView.layer.borderWidth = 1
        denomPickerView.layer.cornerRadius = 5
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
        
        loadingView.startAnimating()
        toast?.hideToast()
        clearFields()
        loadData()
        
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
                   amount: AppContext.shared.collectedAmount,
                   denom: denom) { [weak self] resp, msg in
                    DispatchQueue.main.async {
                        
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
                                self?.toast?.showToastAlert(errMsg, type: .error, dismissable: true)
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
            let dest = segue.destination as? AddressPickController
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
        
    private func queryRewards(validDelegations: [GaiaDelegation]) {
        guard let validNode = AppContext.shared.node else { return }
        for delegation in validDelegations {
            AppContext.shared.key?.queryDelegationRewards(node: validNode, validatorAddr: delegation.validatorAddr) { [weak self] rewards, items, err in
                if let amount = rewards {
                    if AppContext.shared.account?.gaiaKey.validator == delegation.validatorAddr {
                        AppContext.shared.key?.queryValidatorRewards(node: validNode, validator: delegation.validatorAddr) { [weak self] rewards, items, err in
                            if let total = rewards {
                                delegation.allRewards = items
                                delegation.availableReward = total + amount > 0 ? "\(total + amount)" : ""
                                self?.tableView.reloadData()
                            }
                        }
                    } else {
                        delegation.allRewards = items
                        delegation.availableReward = amount > 0 ? "\(amount)" : ""
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
                        let matches = validDelegations.filter { $0.validatorAddr == AppContext.shared.account?.gaiaKey.validator }
                        if matches.count > 0 { AppContext.shared.account?.isValidator = true }

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
                if AppContext.shared.node?.feeDenom == "", let asset = self?.selectedAsset {
                    AppContext.shared.node?.feeDenom = asset.denom ?? ""
                }
                self?.denomPickerView.reloadAllComponents()
                
                if let asset = self?.selectedAsset, let amount = asset.amount?.split(separator: ".").first, let denom = asset.denom {
                    AppContext.shared.account?.isEmpty = false
                    let newAmount = asset.deflatedAmount(decimals: AppContext.shared.nodeDecimals, displayDecimnals: 2)
                    self?.sendAmountButton.isEnabled = !(AppContext.shared.key?.watchMode == true)
                    self?.amountValueLabel.text = newAmount
                    self?.amountDenomLabel.text = asset.upperDenom
                    
                    self?.txFeeLabel.text = amount + " " + denom
                } else {
                    AppContext.shared.account?.isEmpty = true
                    self?.sendAmountButton.isEnabled = false
                    self?.txFeeLabel.text = ""
                    if let message = errMessage, message.count > 0 {
                        if message.contains("connection was lost") {
                            self?.toast?.showToastAlert("Tx broadcasted but not confirmed yet", autoHideAfter: GaiaConstants.autoHideToastTime, type: .validatePending, dismissable: true)
                        } else {
                            self?.toast?.showToastAlert(message, type: .error, dismissable: true)
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
        
        if let tabBar = tabBarController as? GaiaTabBarController {
            AppContext.shared.collectForStaking = true
            AppContext.shared.collectMaxAmount = nil
            AppContext.shared.collectAsset = nil
            AppContext.shared.collectSummary = [
                "Delegate \(denom)",
                "From:\n\(AppContext.shared.key?.address ?? "you")",
                "To:\n\(delegation.validatorAddr)"]
            tabBar.promptForAmount()
            tabBar.onCollectAmountConfirm = { [weak self] in
                tabBar.onCollectAmountConfirm = nil
                if AppContext.shared.node?.securedSigning == true, let tabBar = self?.tabBarController as? GaiaTabBarController {
                    tabBar.onSecurityCheck = { [weak self] succes in
                        tabBar.onSecurityCheck = nil
                        if succes {
                            self?.broadcastDelegate(delegation: delegation, denom: denom, amount: AppContext.shared.collectedAmount)
                        } else {
                            self?.toast?.showToastAlert("The pin you entered is incorrect. Please try again.",  type: .error, dismissable: true)
                        }
                    }
                    tabBar.promptForPin(mode: .sign)
                } else {
                    self?.broadcastDelegate(delegation: delegation, denom: denom, amount: AppContext.shared.collectedAmount)
                }
            }
            return
        }
    }
    
    private func broadcastDelegate(delegation: GaiaDelegation, denom: String, amount: String?) {
        
        if let validAmount = amount, let validNode = AppContext.shared.node, let validKey = AppContext.shared.key, let delegate = AppContext.shared.keysDelegate {
            loadingView.startAnimating()
            toast?.hideToast()
            delegateStake(
                node: validNode,
                clientDelegate: delegate,
                key: validKey,
                feeAmount: defaultFeeSigAmount,
                toValidator: delegation.validatorAddr,
                amount: validAmount,
                denom: denom) { [weak self] resp, msg in
                    if resp != nil {
                        self?.toast?.showToastAlert("Delegation submitted\n[\(msg ?? "...")]", autoHideAfter: GaiaConstants.autoHideToastTime, type: .validatePending, dismissable: true)
                        self?.loadData()
                    } else if let errMsg = msg {
                        self?.loadingView.stopAnimating()
                        if errMsg.contains("connection was lost") {
                            self?.toast?.showToastAlert("Tx broadcasted but not confirmed yet", autoHideAfter: GaiaConstants.autoHideToastTime, type: .validatePending, dismissable: true)
                        } else {
                            self?.toast?.showToastAlert(errMsg, type: .error, dismissable: true)
                        }
                    }
            }
        }
    }
    
    private func handleUnbound(delegation: GaiaDelegation, denom: String) {
        
        if let tabBar = tabBarController as? GaiaTabBarController {
            AppContext.shared.collectForStaking = true
            let maxShares = Coin.deflatedAmountFrom(amount: delegation.shares, decimals: AppContext.shared.nodeDecimals, displayDecimnals: 6)
            AppContext.shared.collectMaxAmount = maxShares
            AppContext.shared.collectAsset = nil
            tabBar.promptForAmount()
            AppContext.shared.collectSummary = [
                "Unbond \(denom)",
                "From:\n\(delegation.validatorAddr)",
                "To:\n\(AppContext.shared.key?.address ?? "you")"]

            tabBar.onCollectAmountConfirm = { [weak self] in
                tabBar.onCollectAmountConfirm = nil
                if AppContext.shared.node?.securedSigning == true, let tabBar = self?.tabBarController as? GaiaTabBarController {
                    tabBar.onSecurityCheck = { [weak self] succes in
                        tabBar.onSecurityCheck = nil
                        if succes {
                            self?.broadcastUnbound(delegation: delegation, denom: denom, amount: AppContext.shared.collectedAmount)
                        } else {
                            self?.toast?.showToastAlert("The pin you entered is incorrect. Please try again.",  type: .error, dismissable: true)
                        }
                    }
                    tabBar.promptForPin(mode: .sign)
                } else {
                    self?.broadcastUnbound(delegation: delegation, denom: denom, amount: AppContext.shared.collectedAmount)
                }
            }
            return
        }
    }
    
    private func broadcastUnbound(delegation: GaiaDelegation, denom: String, amount: String?) {
        
        if let validAmount = amount, let validNode = AppContext.shared.node, let validKey = AppContext.shared.key, let delegate = AppContext.shared.keysDelegate {
            loadingView.startAnimating()
            toast?.hideToast()
            unbondStake(node: validNode, clientDelegate: delegate, key: validKey, feeAmount: defaultFeeSigAmount, fromValidator: delegation.validatorAddr, amount: validAmount, denom: denom) { [weak self] resp, msg in
                if resp != nil {
                    self?.toast?.showToastAlert("Unbonding submitted\n[\(msg ?? "...")]", autoHideAfter: GaiaConstants.autoHideToastTime, type: .validatePending, dismissable: true)
                    self?.loadData()
                } else if let errMsg = msg {
                    self?.loadingView.stopAnimating()
                    if errMsg.contains("connection was lost") {
                        self?.toast?.showToastAlert("Tx broadcasted but not confirmed yet", autoHideAfter: GaiaConstants.autoHideToastTime, type: .validatePending, dismissable: true)
                    } else {
                        self?.toast?.showToastAlert(errMsg, type: .error, dismissable: true)
                    }
                }
            }
        }
    }
    
    private func handleWithdraw(delegation: GaiaDelegation) {
        if AppContext.shared.node?.securedSigning == true, let tabBar = tabBarController as? GaiaTabBarController {
            tabBar.onSecurityCheck = { [weak self] succes in
                tabBar.onSecurityCheck = nil
                if succes {
                    self?.broadcastWithdraw(delegation: delegation)
                } else {
                    self?.toast?.showToastAlert("The pin you entered is incorrect. Please try again.",  type: .error, dismissable: true)
                }
            }
            tabBar.promptForPin(mode: .sign)
        } else {
            broadcastWithdraw(delegation: delegation)
        }
    }
    
    private func broadcastWithdraw(delegation: GaiaDelegation) {
        
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
                        self?.toast?.showToastAlert(errMsg, type: .error, dismissable: true)
                    }
                }
            }
        }
    }
    
    private func handleWithdrawComission(delegation: GaiaDelegation) {
        if AppContext.shared.node?.securedSigning == true, let tabBar = tabBarController as? GaiaTabBarController {
            tabBar.onSecurityCheck = { [weak self] succes in
                tabBar.onSecurityCheck = nil
                if succes {
                    self?.broadcastWithdrawComission(delegation: delegation)
                } else {
                    self?.toast?.showToastAlert("The pin you entered is incorrect. Please try again.",  type: .error, dismissable: true)
                }
            }
            tabBar.promptForPin(mode: .sign)
        } else {
            broadcastWithdrawComission(delegation: delegation)
        }
    }
    
    private func broadcastWithdrawComission(delegation: GaiaDelegation) {
        
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
                        self?.toast?.showToastAlert(errMsg, type: .error, dismissable: true)
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
        self.amountValueLabel.text = self.selectedAsset?.deflatedAmount(decimals: AppContext.shared.nodeDecimals, displayDecimnals: 2)
        self.amountDenomLabel.text = self.selectedAsset?.upperDenom
        let amount = self.selectedAsset?.amount?.split(separator: ".").first ?? "0"
        let denom = self.selectedAsset?.denom ?? ""
        self.txFeeLabel.text = amount + " " + denom
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
        cell.onInfoTap = { items in
            var result: String = ""
            for item in items {
                if let amount = item.amount, let denom = item.denom {
                    result += "\(denom): \(amount)\n"
                }
            }
            self.showFormattedLongAlert(title: "All available for withdraw", message: result)
        }
        if AppContext.shared.account?.gaiaKey.validator == delegation.validatorAddr {
            cell.leftLabel?.textColor = .pendingYellow
        }
        return cell
    }
}

extension GaiaWalletController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let delegation = dataSource[indexPath.item]
        
        DispatchQueue.main.async {
            
            if AppContext.shared.key?.watchMode == true || AppContext.shared.account?.isEmpty == true {
                if AppContext.shared.key?.watchMode == true {
                    self.toast?.showToastAlert("This account is read only", autoHideAfter: GaiaConstants.autoHideToastTime, type: .info, dismissable: true)
                    return
                }
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

                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                
                optionMenu.addAction(withdrawAction)
                optionMenu.addAction(cancelAction)
                
                optionMenu.popoverPresentationController?.sourceView = self.tableView
                
                self.present(optionMenu, animated: true, completion: nil)

                return
            }
            
            self.tapAction(delegation: delegation)
        }
    }
    
    private func tapAction(delegation: GaiaDelegation) {
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
                let maxShares = Coin.deflatedAmountFrom(amount: delegation.shares, decimals: AppContext.shared.nodeDecimals, displayDecimnals: 6)
                AppContext.shared.collectMaxAmount = maxShares
                AppContext.shared.redelgateFrom = delegation.validatorAddr
                self?.tabBarController?.selectedIndex = 1
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            optionMenu.addAction(withdrawAction)
            optionMenu.addAction(redelegateAction)
            optionMenu.addAction(delegateAction)
            optionMenu.addAction(unboundAction)
            optionMenu.addAction(cancelAction)
            optionMenu.popoverPresentationController?.sourceView = self.tableView
            self.present(optionMenu, animated: true, completion: nil)
        }
    }
}
