//
//  GaiaGovernanceController.swift
//  Cosmos Client
//
//  Created by Calin Chitu on 14/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi

class GaiaGovernanceController: UIViewController, ToastAlertViewPresentable, TerraOraclesCapable {

    var toast: ToastAlertView?

    var node: GaiaNode?
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
    
    var dataSource: [(denom: String, price: Double)] = []
    var offeredDenom: String?  = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toast = createToastAlert(creatorView: view, holderUnderView: toastHolderUnderView, holderTopDistanceConstraint: toastHolderTopConstraint, coveringView: topNavBarView)
        bottomTabbarView.onTap = { [weak self] index in
            switch index {
            case 0:
                self?.onUnwind?(0)
                self?.performSegue(withIdentifier: "UnwindToWallet", sender: nil)
            case 1: self?.dismiss(animated: false)
            case 3: self?.performSegue(withIdentifier: "nextSegue", sender: index)
            default: break
            }
        }
        
        let _ = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main) { [weak self] note in
            self?.node?.getStatus {
                if self?.node?.state == .unknown {
                    self?.performSegue(withIdentifier: "UnwindToNodes", sender: self)
                } else if let validNode = self?.node {
                    self?.loadData(validNode: validNode)
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
        
        bottomTabbarView.selectIndex(2)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if forwardCounter > 0 {
            UIView.setAnimationsEnabled(true)
            self.performSegue(withIdentifier: "nextSegue", sender: 3)
            forwardCounter = 0
            return
        }
        
        guard !lockLifeCicleDelegates else {
            lockLifeCicleDelegates = false
            return
        }
        
        if let validNode = node {
            loadData(validNode: validNode)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dataSource = []
        offeredDenom = nil
        toast?.hideToastAlert()
        tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let index = sender as? Int {
            
            let dest = segue.destination as? GaiaSettingsController
            dest?.forwardCounter = index - 3
            dest?.node = node
            dest?.account = account
            dest?.key = key
            dest?.onUnwind = { [weak self] index in
                self?.lockLifeCicleDelegates = true
                self?.bottomTabbarView.selectIndex(-1)
                if index == 0 { self?.onUnwind?(index) }
            }
            forwardCounter = 0
        }
    }

    func loadData(validNode: GaiaNode) {
        
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        
        loadingView.startAnimating()
        retrieveAllActives(node: validNode) { [weak self] actives, errMsg in
            self?.dataSource = []
            self?.dataSource.insert((validNode.stakeDenom, 1.0), at: 0)
            self?.loadingView.stopAnimating()
            if let validActives = actives {
                for active in validActives {
                    dispatchGroup.enter()
                    self?.retrievePrice(node: validNode, active: active) { price, errMsg in
                        if let validprice = price {
                            let dv = Double(validprice.replacingOccurrences(of: "\"", with: "")) ?? 0
                            self?.dataSource.append((active, dv))
                        } else if let validErr = errMsg {
                            self?.toast?.showToastAlert(validErr, autoHideAfter: 5, type: .error, dismissable: true)
                        } else {
                            self?.toast?.showToastAlert("Ooops! I Failed", autoHideAfter: 5, type: .error, dismissable: true)
                        }
                        dispatchGroup.leave()
                    }
                }
            } else if let validErr = errMsg {
                self?.toast?.showToastAlert(validErr, autoHideAfter: 5, type: .error, dismissable: true)
            } else {
                self?.toast?.showToastAlert("Ooops! I Failed", autoHideAfter: 5, type: .error, dismissable: true)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            self.tableView.reloadData()
        }
    }
    
    @IBAction func unwindToGovernance(segue:UIStoryboardSegue) {
        bottomTabbarView.selectIndex(2)
    }
    
    private func handleSwap(offerDenom: String, askDenom: String) {
        
        print("Should swap to \(askDenom)")
        showAmountAlert(title: "Type the amount of \(offerDenom) you want to swap to \(askDenom)", message: "", placeholder: "0 \(askDenom)") { amount in
            if let validAmount = amount, let validNode = self.node, let validKey = self.key, let delegate = self.keysDelegate {
                self.loadingView.startAnimating()
                self.swapActives(node: validNode,
                                 clientDelegate: delegate,
                                 key: validKey,
                                 offerAmount: validAmount,
                                 offerDenom: offerDenom,
                                 askDenom: askDenom,
                                 feeAmount: self.feeAmount) { [weak self] resp, err in
                                    self?.loadingView.stopAnimating()
                                    if err == nil {
                                        self?.toast?.showToastAlert("Swap successfull", autoHideAfter: 5, type: .info, dismissable: true)
                                    } else if let errMsg = err {
                                        self?.toast?.showToastAlert(errMsg, autoHideAfter: 5, type: .error, dismissable: true)
                                    }
                }
            }
        }
    }
}

extension GaiaGovernanceController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GaiaOraclesCellID", for: indexPath) as! GaiaOracleCell
        cell.configure(proposal: dataSource[indexPath.item])
        return cell
    }
    
}

extension GaiaGovernanceController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tapped = dataSource[indexPath.item]
        DispatchQueue.main.async {
            if let validOffered = self.offeredDenom {
                self.toast?.hideToastAlert()
                self.handleSwap(offerDenom: validOffered, askDenom: tapped.denom)
                self.offeredDenom = nil
            } else {
                self.offeredDenom = tapped.denom
                self.toast?.showToastAlert("Pick the denom you want to convert \(tapped.denom) to!", type: .validatePending, dismissable: false)
            }
        }
    }
}

class GaiaOracleCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    func configure(proposal: (denom: String, price: Double)) {
        let strAmount = String(format: "%.6f", proposal.price)
        nameLabel.text = proposal.denom
        priceLabel.text = strAmount
    }
    
}
