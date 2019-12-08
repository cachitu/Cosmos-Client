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
    
    var node: TDMNode?
    var key: GaiaKey?
    var keysDelegate: LocalClient?

    var account: GaiaAccount?
    var feeAmount: String { return node?.defaultTxFee  ?? "0" }

    @IBOutlet weak var loadingView: CustomLoadingView!
    @IBOutlet weak var toastHolderUnderView: UIView!
    @IBOutlet weak var toastHolderTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var topNavBarView: UIView!
    @IBOutlet weak var bottomTabbarView: CustomTabBar!
    @IBOutlet weak var bottomTabbarDownConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    
    var forwardCounter = 0
    var onUnwind: ((_ toIndex: Int) -> ())?
    var lockLifeCicleDelegates = false

    var dataSource: [GaiaValidator] = []
    var redelgateFrom: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        toast = createToastAlert(creatorView: view, holderUnderView: toastHolderUnderView, holderTopDistanceConstraint: toastHolderTopConstraint, coveringView: topNavBarView)
        bottomTabbarView.onTap = { [weak self] index in
            let segueName = (self?.node?.type == .terra || self?.node?.type == .terra_118) ? "nextSegueTerra" : "nextSegue"
            switch index {
            case 0: self?.dismiss(animated: false)
            case 2:
                self?.performSegue(withIdentifier: segueName, sender: index)
            case 3:
                self?.performSegue(withIdentifier: segueName, sender: index)
                UIView.setAnimationsEnabled(false)
            default: break
            }
        }
        
        let _ = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main) { [weak self] note in
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
        guard !lockLifeCicleDelegates else { return }
        if forwardCounter > 0 {
            bottomTabbarView.selectIndex(-1)
            return
        }
        
        bottomTabbarView.selectIndex(1)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !lockLifeCicleDelegates else {
            lockLifeCicleDelegates = false
            return
        }
        if forwardCounter > 0 {
            if forwardCounter == 1 { UIView.setAnimationsEnabled(true) }
            let segueName = (node?.type == .terra || node?.type == .terra_118) ? "nextSegueTerra" : "nextSegue"
            self.performSegue(withIdentifier: segueName, sender: forwardCounter + 1)
            forwardCounter = 0
            return
        }
        
        loadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        redelgateFrom = nil
        toast?.hideToast()
    }
    
    func loadData() {
        
        if let validNode = node {
            loadingView.startAnimating()
            retrieveAllValidators(node: validNode) { [weak self] validators, errMsg in
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
                     if let redelagateAddr = self?.redelgateFrom {
                        self?.toast?.showToastAlert("Tap any validator to redelegate from \(redelagateAddr)", type: .validatePending, dismissable: false)
                    }
                } else if let validErr = errMsg {
                    if validErr.contains("connection was lost") {
                        self?.toast?.showToastAlert("Tx broadcasted but not confirmed yet", autoHideAfter: 5, type: .validatePending, dismissable: true)
                    } else {
                        self?.toast?.showToastAlert(validErr, autoHideAfter: 15, type: .error, dismissable: true)
                    }
                } else {
                    self?.toast?.showToastAlert("Ooops! I Failed", autoHideAfter: 15, type: .error, dismissable: true)
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "MoreSegueID", let validator = sender as? GaiaValidator {
            let dest = segue.destination as? GaiaDelegationsController
            dest?.node = node
            dest?.account = account
            dest?.key = key
            dest?.validator = validator
        }
        if let index = sender as? Int {
            if node?.type == .terra || node?.type == .terra_118 {
                let dest = segue.destination as? GaiaOraclesController
                dest?.node = node
                dest?.account = account
                dest?.key = key
                dest?.keysDelegate = keysDelegate
                dest?.forwardCounter = index - 2
                dest?.onUnwind = { [weak self] index in
                    self?.bottomTabbarView.selectIndex(-1)
                    self?.lockLifeCicleDelegates = true
                }
            } else {
                let dest = segue.destination as? GaiaGovernanceController
                dest?.node = node
                dest?.account = account
                dest?.key = key
                dest?.keysDelegate = keysDelegate
                dest?.forwardCounter = index - 2
                dest?.onUnwind = { [weak self] index in
                    self?.bottomTabbarView.selectIndex(-1)
                    self?.lockLifeCicleDelegates = true
                }

            }
            forwardCounter = 0
        }
    }

    @IBAction func unwindToValidator(segue:UIStoryboardSegue) {
        bottomTabbarView.selectIndex(1)
    }
    
    private func handleUnjail(validator: GaiaValidator) {
        
        guard let validNode = node, let validKey = key, let keysDelegate = keysDelegate else { return }
        
        loadingView.startAnimating()
        validator.unjail(node: validNode, clientDelegate: keysDelegate, key: validKey, feeAmount: feeAmount) { [weak self] resp, errMsg in
            self?.loadingView.stopAnimating()
            if let msg = errMsg {
                if msg.contains("connection was lost") {
                    self?.toast?.showToastAlert("Tx broadcasted but not confirmed yet", autoHideAfter: 5, type: .validatePending, dismissable: true)
                } else {
                    self?.toast?.showToastAlert(msg, autoHideAfter: 15, type: .error, dismissable: true)
                }
            } else  {
                self?.toast?.showToastAlert("Unjail request submited", autoHideAfter: 13, type: .info, dismissable: true)
                self?.tableView.reloadData()
            }
        }
    }
    
    private func handleRedelegate(redelgateFrom: String, validator: GaiaValidator) {
        print("redelegate from \(redelgateFrom) to \(validator.validator)")
        node?.getStakingInfo() { [weak self] denom in
            self?.showAmountAlert(title: "Type the amount of \(denom ?? "stake") you want to redelegate to:", message: "\(validator.validator)\nfrom\n\(redelgateFrom)", placeholder: "0 \(denom ?? "stake")") { amount in
                if let validAmount = amount, let validNode = self?.node, let validKey = self?.key, let delegate = self?.keysDelegate {
                    self?.loadingView.startAnimating()
                    self?.redelegateStake(
                        node: validNode,
                        clientDelegate: delegate,
                        key: validKey,
                        feeAmount: self?.feeAmount ?? "0",
                        fromValidator: redelgateFrom,
                        toValidator: validator.validator,
                        amount: validAmount) { (resp, err) in
                            self?.redelgateFrom = nil
                            if err == nil {
                                self?.toast?.showToastAlert("Redelegation successfull", autoHideAfter: 15, type: .info, dismissable: true)
                                self?.key?.getDelegations(node: validNode) { [weak self] delegations, error in
                                    self?.loadingView.stopAnimating()
                                    self?.loadData()
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
    }
    
    private func handleDelegate(to validator: GaiaValidator) {
        
        print("Should delegate to \(validator.validator)")
        node?.getStakingInfo() { [weak self] denom in
            self?.showAmountAlert(title: "Type the amount of \(denom ?? "stake") you want to delegate to:", message: "\(validator.validator)", placeholder: "0 \(denom ?? "stake")") { amount in
                if let validAmount = amount, let validNode = self?.node, let validKey = self?.key, let delegate = self?.keysDelegate {
                    self?.loadingView.startAnimating()
                    self?.delegateStake (
                        node: validNode,
                        clientDelegate: delegate,
                        key: validKey,
                        feeAmount: self?.feeAmount ?? "0",
                        toValidator: validator.validator,
                        amount: validAmount,
                        denom: denom ?? "stake") { (resp, err) in
                            if err == nil {
                                self?.toast?.showToastAlert("Delegation successfull", autoHideAfter: 15, type: .info, dismissable: true)
                                self?.key?.getDelegations(node: validNode) { [weak self] delegations, error in
                                    self?.loadingView.stopAnimating()
                                    self?.loadData()
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
    }
}


extension GaiaValidatorsController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let validator: Bool = account?.isValidator ?? false
        switch (section, validator) {
        case (0, true): return 1
        case (0, false): return dataSource.count
        case (1, true): return dataSource.count
        default: return dataSource.count
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        let validator: Bool = account?.isValidator ?? false
        return validator ? 2 : 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GaiaValidatorCellID", for: indexPath) as! GaiaValidatorCell
        let validator: Bool = account?.isValidator ?? false
        switch (indexPath.section, validator) {
        case (0, true):
            let matches = dataSource.filter { $0.validator == account?.gaiaKey.validator }
            let poz = dataSource.firstIndex { $0.validator == account?.gaiaKey.validator }
            let index = poz?.advanced(by: 0) ?? 0
            if let valid = matches.first {
                cell.configure(account: account, validator: valid, index: index + 1)
            }
        case (0, false), (1, true):
            let validator = dataSource[indexPath.item]
            cell.configure(account: account, validator: validator, index: indexPath.item + 1)
        default: break
        }

        return cell
    }
    
}

extension GaiaValidatorsController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard self.node?.isReadOnly != true else {
            self.toast?.showToastAlert("This account is read only", autoHideAfter: 5, type: .info, dismissable: true)
            return
        }

        var validator = dataSource[indexPath.item]
        
        let isValidator: Bool = account?.isValidator ?? false
        switch (indexPath.section, isValidator) {
        case (0, true):
            let matches = dataSource.filter { $0.validator == account?.gaiaKey.validator }
            if let match = matches.first {
                validator = match
            }
        default: break
        }

        DispatchQueue.main.async {
            if let redelagateAddr = self.redelgateFrom {
                
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
                optionMenu.addAction(delegateAction)
                optionMenu.addAction(cancelAction)
                
                if validator.jailed == true {
                    let unjailAction = UIAlertAction(title: "Unjail", style: .default) { [weak self] alertAction in
                        self?.handleUnjail(validator: validator)
                    }
                    optionMenu.addAction(unjailAction)
                }
                
                self.present(optionMenu, animated: true, completion: nil)
            }
        }
    }
}
