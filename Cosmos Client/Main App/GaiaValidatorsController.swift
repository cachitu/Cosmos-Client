//
//  GaiaValidatorsController.swift
//  Cosmos Client
//
//  Created by Calin Chitu on 14/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi

class GaiaValidatorsController: UIViewController, ToastAlertViewPresentable, GaiaValidatorsCapable, GaiaKeysManagementCapable {
    
    var toast: ToastAlertView?
    var validatorState = "bonded"
    var defaultFeeSigAmount: String { return AppContext.shared.node?.feeAmount  ?? "0" }

    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var loadingView: CustomLoadingView!
    @IBOutlet weak var toastHolderUnderView: UIView!
    @IBOutlet weak var toastHolderTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var topNavBarView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var logsButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var logsButton: RoundedButton!
    @IBAction func logsAction(_ sender: UIButton) {
    }
    
    @IBAction func getUnbondingsAction(_ sender: UIButton) {
        getUnbondings()
    }
    
    @IBAction func segmentControlAction(_ sender: UISegmentedControl) {
        validatorState = sender.selectedSegmentIndex == 2 ? "unbonded" : sender.selectedSegmentIndex == 1 ? "unbonding" : "bonded"
        loadData(status: validatorState)
    }
    
    var dataSource: [GaiaValidator] = []
    private weak var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        toast = createToastAlert(creatorView: view, holderUnderView: toastHolderUnderView, holderTopDistanceConstraint: toastHolderTopConstraint, coveringView: topNavBarView)
        
        let _ = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main) { [weak self] note in
            guard !AppContext.shared.collectScreenOpen else { return }
            AppContext.shared.node?.getStatus {
                if AppContext.shared.node?.state == .unknown {
                    self?.performSegue(withIdentifier: "UnwindToNodes", sender: self)
                } else {
                    self?.loadData(status: self?.validatorState ?? "bonded")
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.logsButton.backgroundColor = UIColor.pendingYellow
        AppContext.shared.onHashPolingPending = {
            guard AppContext.shared.key?.watchMode == false else {
                return
            }
            self.logsButtonBottomConstraint.constant = 8
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
        }
        AppContext.shared.onHashPolingDone = {
            self.logsButtonBottomConstraint.constant = -50
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
        }
        
        if let hash = AppContext.shared.lastSubmitedHash() {
            AppContext.shared.startHashPoling(hash: hash)
        } else {
            self.logsButtonBottomConstraint.constant = -50
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        loadData(status: validatorState)
        timer = Timer.scheduledTimer(withTimeInterval: GaiaConstants.refreshInterval * 3, repeats: true) { [weak self] timer in
            self?.loadData(status: self?.validatorState ?? "bonded")
        }

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AppContext.shared.redelgateFrom = nil
        toast?.hideToast()
        timer?.invalidate()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        toast?.hideToast()
    }

    func loadData(status: String) {
        
        if let validNode = AppContext.shared.node {
            
            if let hash = AppContext.shared.lastSubmitedHash() {
                AppContext.shared.startHashPoling(hash: hash)
            }

            loadingView.startAnimating()
            retrieveAllValidators(node: validNode, status: status) { [weak self] validators, errMsg in
                self?.loadingView.stopAnimating()
                if let validValidators = validators {
                    for validator in validValidators {
                        validNode.knownValidators[validator.validator] = validator.moniker
                    }
                    if let savedNodes = PersistableGaiaNodes.loadFromDisk() as? PersistableGaiaNodes {
                        for savedNode in savedNodes.nodes {
                            if savedNode.network == validNode.network {
                                savedNode.knownValidators = validNode.knownValidators
                            }
                        }
                        PersistableGaiaNodes(nodes: savedNodes.nodes).savetoDisk()
                    }
                    self?.dataSource = []
                    let jailed = validators?.filter() { $0.jailed == true }.sorted() { left, right in
                        left.votingPower > right.votingPower
                    } ?? []
                    let active = validators?.filter() { $0.jailed == false }.sorted() { left, right in
                        left.votingPower > right.votingPower
                    } ?? []
                    self?.dataSource.append(contentsOf: active)
                    self?.dataSource.append(contentsOf: jailed)
                    
                    self?.tableView.reloadData()
                    if let redelagateAddr = AppContext.shared.redelgateFrom {
                        self?.timer?.invalidate()
                        self?.toast?.showToastAlert("Tap any validator to redelegate from \(redelagateAddr)", type: .validatePending, dismissable: false)
                    }
                } else if let validErr = errMsg {
                    if validErr.contains("connection was lost") {
                        self?.toast?.showToastAlert("Tx broadcasted but not confirmed yet", autoHideAfter: GaiaConstants.autoHideToastTime, type: .validatePending, dismissable: true)
                    } else {
                        self?.toast?.showToastAlert(validErr, type: .error, dismissable: true)
                    }
                } else {
                    self?.toast?.showToastAlert("Ooops! I Failed", autoHideAfter: GaiaConstants.autoHideToastTime, type: .error, dismissable: true)
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "MoreSegueID", let validator = sender as? GaiaValidator {
            let dest = segue.destination as? GaiaDelegationsController
            dest?.validator = validator
        }
    }

    @IBAction func unwindToValidator(segue:UIStoryboardSegue) {
    }
    
    private func handleUnjail(validator: GaiaValidator) {
        
        guard let validNode = AppContext.shared.node, let validKey = AppContext.shared.key, let keysDelegate = AppContext.shared.keysDelegate else { return }
        
        loadingView.startAnimating()
        validator.unjail(node: validNode, clientDelegate: keysDelegate, key: validKey) { [weak self] resp, errMsg in
            self?.loadingView.stopAnimating()
            if let msg = errMsg {
                if msg.contains("connection was lost") {
                    self?.toast?.showToastAlert("Tx broadcasted but not confirmed yet", autoHideAfter: GaiaConstants.autoHideToastTime, type: .validatePending, dismissable: true)
                } else {
                    self?.toast?.showToastAlert(msg, type: .error, dismissable: true)
                }
            } else  {
                if let hash = AppContext.shared.lastSubmitedHash() {
                    AppContext.shared.startHashPoling(hash: hash)
                }

                self?.toast?.showToastAlert("Unjail request submited", autoHideAfter: GaiaConstants.autoHideToastTime, type: .info, dismissable: true)
                self?.tableView.reloadData()
            }
        }
    }
    
    
    private func handleRedelegate(redelgateFrom: String, validator: GaiaValidator) {
        
        if let tabBar = tabBarController as? GaiaTabBarController {
            AppContext.shared.colletForStaking = true
            AppContext.shared.colletAsset = nil
            tabBar.promptForAmount()
            AppContext.shared.collectSummary = [
                "Redelegate \(AppContext.shared.node?.stakeDenom ?? "")",
                "From:\n\(redelgateFrom)",
                "To:\n\(validator.validator)"]

            tabBar.onCollectAmountCancel = { [weak self] in
                AppContext.shared.redelgateFrom = nil
                self?.toast?.hideToast()
            }
            tabBar.onCollectAmountConfirm = { [weak self] in
                tabBar.onCollectAmountConfirm = nil
                if AppContext.shared.node?.securedSigning == true, let tabBar = self?.tabBarController as? GaiaTabBarController {
                    tabBar.onSecurityCheck = { [weak self] succes in
                        tabBar.onSecurityCheck = nil
                        if succes {
                            self?.broadcastRedelegate(redelgateFrom: redelgateFrom, validator: validator, amount: AppContext.shared.collectedAmount)
                        } else {
                            self?.toast?.showToastAlert("The pin you entered is incorrect. Please try again.",  type: .error, dismissable: true)
                        }
                    }
                    tabBar.promptForPin(mode: .sign)
                } else {
                    self?.broadcastRedelegate(redelgateFrom: redelgateFrom, validator: validator, amount: AppContext.shared.collectedAmount)
                }
            }
            return
        }
    }

    private func broadcastRedelegate(redelgateFrom: String, validator: GaiaValidator, amount: String?) {
        
        if let validAmount = amount, let validNode = AppContext.shared.node, let validKey = AppContext.shared.key, let delegate = AppContext.shared.keysDelegate {
            loadingView.startAnimating()
            redelegateStake(
                node: validNode,
                clientDelegate: delegate,
                key: validKey,
                feeAmount: defaultFeeSigAmount,
                fromValidator: redelgateFrom,
                toValidator: validator.validator,
                amount: validAmount) { [weak self] resp, msg in
                    AppContext.shared.redelgateFrom = nil
                    self?.timer = Timer.scheduledTimer(withTimeInterval: GaiaConstants.refreshInterval * 3, repeats: true) { [weak self] timer in
                        self?.loadData(status: self?.validatorState ?? "bonded")
                    }
                    
                    if resp != nil {
                        self?.toast?.showToastAlert("Redelegation submitted\n[\(msg ?? "...")]", autoHideAfter: GaiaConstants.autoHideToastTime, type: .validatePending, dismissable: true)
                        if let hash = AppContext.shared.lastSubmitedHash() {
                            AppContext.shared.startHashPoling(hash: hash)
                        }
                        
                        AppContext.shared.key?.getDelegations(node: validNode) { [weak self] delegations, error in
                            self?.loadingView.stopAnimating()
                            self?.loadData(status: self?.validatorState ?? "bonded")
                        }
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
    
    private func handleDelegate(to validator: GaiaValidator) {
        
        if let tabBar = tabBarController as? GaiaTabBarController {
            AppContext.shared.colletForStaking = true
            AppContext.shared.colletMaxAmount = nil
            AppContext.shared.colletAsset = nil
            AppContext.shared.collectSummary = [
                "Delegate \(AppContext.shared.node?.stakeDenom ?? "")",
                "From:\n\(AppContext.shared.key?.address ?? "you")",
                "To:\n\(validator.validator)"]
            tabBar.promptForAmount()
            tabBar.onCollectAmountConfirm = { [weak self] in
                tabBar.onCollectAmountConfirm = nil
                if AppContext.shared.node?.securedSigning == true, let tabBar = self?.tabBarController as? GaiaTabBarController {
                    tabBar.onSecurityCheck = { [weak self] succes in
                        tabBar.onSecurityCheck = nil
                        if succes {
                            self?.broadcastDelegate(to: validator, amount: AppContext.shared.collectedAmount)
                        } else {
                            self?.toast?.showToastAlert("The pin you entered is incorrect. Please try again.",  type: .error, dismissable: true)
                        }
                    }
                    tabBar.promptForPin(mode: .unlock)
                } else {
                    self?.broadcastDelegate(to: validator, amount: AppContext.shared.collectedAmount)
                }
            }
            return
        }
    }
    
    private func broadcastDelegate(to validator: GaiaValidator, amount: String?) {
        
        AppContext.shared.node?.getStakingInfo() { [weak self] denom in
            if let validAmount = amount, let validNode = AppContext.shared.node, let validKey = AppContext.shared.key, let delegate = AppContext.shared.keysDelegate {
                self?.loadingView.startAnimating()
                self?.delegateStake (
                    node: validNode,
                    clientDelegate: delegate,
                    key: validKey,
                    feeAmount: self?.defaultFeeSigAmount ?? "0",
                    toValidator: validator.validator,
                    amount: validAmount,
                    denom: denom ?? "stake") { resp, msg in
                        if resp != nil {
                            if let hash = AppContext.shared.lastSubmitedHash() {
                                AppContext.shared.startHashPoling(hash: hash)
                            }
                            self?.toast?.showToastAlert("Delegation submitted\n[\(msg ?? "...")]", autoHideAfter: GaiaConstants.autoHideToastTime, type: .validatePending, dismissable: true)
                            AppContext.shared.key?.getDelegations(node: validNode) { [weak self] delegations, error in
                                self?.loadingView.stopAnimating()
                                self?.loadData(status: self?.validatorState ?? "bonded")
                            }
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
    
    private func getUnbondings() {
        if let validNode = AppContext.shared.node, let validKey = AppContext.shared.key {
            validKey.getUnbondingDelegations(node: validNode) { [weak self] (unbondings, error) in
                if unbondings?.count ?? 0 > 0 {
                    var result = "Unbondings:\n"
                    for unbonding in unbondings ?? [] {
                        for entry in unbonding.entries ?? [] {
                            if let balance = entry.balance, let ctime = entry.completionTime {
                                result += balance + " - " + ctime + "\n"
                            }
                        }
                    }
                    self?.toast?.showToastAlert(result, type: .info, dismissable: true)
                } else {
                    self?.toast?.showToastAlert("No unbondings in progress", autoHideAfter: 5, type: .info, dismissable: true)
                }
            }
        }
    }
}


extension GaiaValidatorsController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let validator: Bool = AppContext.shared.account?.isValidator ?? false
        switch (section, validator) {
        case (0, true): return dataSource.count > 0 ? 1 : 0
        case (0, false): return dataSource.count
        case (1, true): return dataSource.count
        default: return dataSource.count
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        let validator: Bool = AppContext.shared.account?.isValidator ?? false
        return validator ? 2 : 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GaiaValidatorCellID", for: indexPath) as! GaiaValidatorCell
        let validator: Bool = AppContext.shared.account?.isValidator ?? false
        switch (indexPath.section, validator) {
        case (0, true):
            let matches = dataSource.filter {
                let compareTo = AppContext.shared.account?.gaiaKey.validator ?? ""
                return $0.validator == compareTo
            }
            let poz = dataSource.firstIndex { $0.validator == AppContext.shared.account?.gaiaKey.validator }
            let index = poz?.advanced(by: 0) ?? 0
            if let valid = matches.first {
                cell.configure(account: AppContext.shared.account, validator: valid, index: index + 1, image: AppContext.shared.node?.nodeLogoWhite)
            }
        case (0, false), (1, true):
            let validator = dataSource[indexPath.item]
            cell.configure(account: AppContext.shared.account, validator: validator, index: indexPath.item + 1, image: AppContext.shared.node?.nodeLogoWhite)
        default: break
        }

        return cell
    }
    
}

extension GaiaValidatorsController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var validator = dataSource[indexPath.item]
        
        let isValidator: Bool = AppContext.shared.account?.isValidator ?? false
        switch (indexPath.section, isValidator) {
        case (0, true):
            let matches = dataSource.filter { $0.validator == AppContext.shared.account?.gaiaKey.validator }
            if let match = matches.first {
                validator = match
            }
        default: break
        }

        DispatchQueue.main.async {
            if let redelagateAddr = AppContext.shared.redelgateFrom {
                
                self.handleRedelegate(redelgateFrom: redelagateAddr, validator: validator)
            } else {
                
                let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                let detailsAction = UIAlertAction(title: "Validator Delegations", style: .default) { [weak self] alertAction in
                    self?.performSegue(withIdentifier: "MoreSegueID", sender: validator)
                }
                let shareAction = UIAlertAction(title: "Share Address", style: .default) { [weak self] alertAction in
                    let text = "\(validator.validator)"
                    let textShare = [ text ]
                    let activityViewController = UIActivityViewController(activityItems: textShare , applicationActivities: nil)
                    activityViewController.popoverPresentationController?.sourceView = self?.view
                    self?.present(activityViewController, animated: true, completion: nil)
                }
                let delegateAction = UIAlertAction(title: "Delegate", style: .default) { [weak self] alertAction in
                    
                    self?.handleDelegate(to: validator)
                }
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                
                optionMenu.addAction(detailsAction)
                optionMenu.addAction(shareAction)
                if AppContext.shared.key?.watchMode != true, AppContext.shared.account?.isEmpty != true { optionMenu.addAction(delegateAction) }
                optionMenu.addAction(cancelAction)
                
//                if validator.jailed == true {
//                    let unjailAction = UIAlertAction(title: "Unjail", style: .default) { [weak self] alertAction in
//                        self?.handleUnjail(validator: validator)
//                    }
//                    optionMenu.addAction(unjailAction)
//                }
                
                self.present(optionMenu, animated: true, completion: nil)
            }
        }
    }
}
