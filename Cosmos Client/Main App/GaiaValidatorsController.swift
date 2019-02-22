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
    
    var node: GaiaNode?
    var key: GaiaKey?
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
            switch index {
            case 0: self?.dismiss(animated: false)
            case 2: self?.performSegue(withIdentifier: "nextSegue", sender: index)
            case 3:
                self?.performSegue(withIdentifier: "nextSegue", sender: index)
                UIView.setAnimationsEnabled(false)
            default: break
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
            self.performSegue(withIdentifier: "nextSegue", sender: forwardCounter + 1)
            forwardCounter = 0
            return
        }
        
        loadData()
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
                    self?.dataSource = validValidators.sorted() { (left, right) -> Bool in
                        left.votingPower > right.votingPower
                    }
                    self?.tableView.reloadData()
                     if let redelagateAddr = self?.redelgateFrom {
                        self?.toast?.showToastAlert("Tap any validator to redelegate from \(redelagateAddr)", type: .validatePending, dismissable: false)
                    }
                } else if let validErr = errMsg {
                    self?.toast?.showToastAlert(validErr, autoHideAfter: 5, type: .error, dismissable: true)
                } else {
                    self?.toast?.showToastAlert("Ooops! I Failed", autoHideAfter: 5, type: .error, dismissable: true)
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let index = sender as? Int {
            let dest = segue.destination as? GaiaGovernanceController
            dest?.node = node
            dest?.account = account
            dest?.key = key
            dest?.forwardCounter = index - 2
            dest?.onUnwind = { [weak self] index in
                self?.bottomTabbarView.selectIndex(-1)
                self?.lockLifeCicleDelegates = true
            }
            forwardCounter = 0
        }
    }

    @IBAction func unwindToValidator(segue:UIStoryboardSegue) {
        bottomTabbarView.selectIndex(1)
    }
    
    private func handleUnjail(validator: GaiaValidator) {
        
        guard let validNode = node, let validKey = key else { return }
        
        loadingView.startAnimating()
        validator.unjail(node: validNode, key: validKey, feeAmount: feeAmount) { [weak self] resp, errMsg in
            self?.loadingView.stopAnimating()
            if let msg = errMsg {
                self?.toast?.showToastAlert(msg, autoHideAfter: 3, type: .error, dismissable: true)
            } else  {
                self?.toast?.showToastAlert("Unjail request submited", autoHideAfter: 3, type: .info, dismissable: true)
                self?.tableView.reloadData()
            }
        }
    }
    
    private func handleRedelegate(redelgateFrom: String, validator: GaiaValidator) {
        print("redelegate from \(redelgateFrom) to \(validator.validator)")
        node?.getStakingInfo() { [weak self] denom in
            self?.showAmountAlert(title: "Type the amount of \(denom ?? "stake") you want to redelegate to:", message: "\(validator.validator)\nfrom\n\(redelgateFrom)", placeholder: "0 \(denom ?? "stake")") { amount in
                if let validAmount = amount, let validNode = self?.node, let validKey = self?.key {
                    self?.loadingView.startAnimating()
                    self?.redelegateStake(
                        node: validNode,
                        key: validKey,
                        feeAmount: self?.feeAmount ?? "0",
                        fromValidator: redelgateFrom,
                        toValidator: validator.validator,
                        amount: validAmount) { (resp, err) in
                            self?.redelgateFrom = nil
                            if err == nil {
                                self?.toast?.showToastAlert("Redelegation successfull", autoHideAfter: 5, type: .info, dismissable: true)
                                self?.key?.getDelegations(node: validNode) { [weak self] delegations, error in
                                    self?.loadingView.stopAnimating()
                                    self?.loadData()
                                }
                            } else if let errMsg = err {
                                self?.loadingView.stopAnimating()
                                self?.toast?.showToastAlert(errMsg, autoHideAfter: 5, type: .error, dismissable: true)
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
                if let validAmount = amount, let validNode = self?.node, let validKey = self?.key {
                    self?.loadingView.startAnimating()
                    self?.delegateStake (
                        node: validNode,
                        key: validKey,
                        feeAmount: self?.feeAmount ?? "0",
                        toValidator: validator.validator,
                        amount: validAmount,
                        denom: denom ?? "stake") { (resp, err) in
                            if err == nil {
                                self?.toast?.showToastAlert("Delegation successfull", autoHideAfter: 5, type: .info, dismissable: true)
                                self?.key?.getDelegations(node: validNode) { [weak self] delegations, error in
                                    self?.loadingView.stopAnimating()
                                    self?.loadData()
                                }
                            } else if let errMsg = err {
                                self?.loadingView.stopAnimating()
                                self?.toast?.showToastAlert(errMsg, autoHideAfter: 5, type: .error, dismissable: true)
                            }
                    }
                }
            }
        }
    }

}


extension GaiaValidatorsController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GaiaValidatorCellID", for: indexPath) as! GaiaValidatorCell
        let validator = dataSource[indexPath.item]
        cell.configure(validator: validator, index: indexPath.item)
        return cell
    }
    
}

extension GaiaValidatorsController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let validator = dataSource[indexPath.item]

        DispatchQueue.main.async {
            if let redelagateAddr = self.redelgateFrom {
                
                self.handleRedelegate(redelgateFrom: redelagateAddr, validator: validator)
            } else {
                
                let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                let detailsAction = UIAlertAction(title: "Validator details", style: .default) { [weak self] alertAction in
                    self?.toast?.showToastAlert("Soon to come", autoHideAfter: 5, type: .info, dismissable: true)
                }
                let delegateAction = UIAlertAction(title: "Delegate", style: .default) { [weak self] alertAction in
                    self?.handleDelegate(to: validator)
                }
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                
                optionMenu.addAction(detailsAction)
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
