//
//  GaiaOraclesController.swift
//  Kommet
//
//  Created by Calin Chitu on 16/11/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi

class GaiaOraclesController: UIViewController, ToastAlertViewPresentable, TerraOraclesCapable {

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
    
    var dataSource: [(denom: String, price: Double, amount: String)] = []
    var offeredDenom: String?  = nil
    private weak var timer: Timer?

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
        
        timer = Timer.scheduledTimer(withTimeInterval: 7, repeats: true) { [weak self] timer in
            self?.loadAccount()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dataSource = []
        offeredDenom = nil
        toast?.hideToastAlert()
        timer?.invalidate()
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

    private func loadAccount() {
        
        if let validNode = node, let validKey = key {
            loadingView.startAnimating()
            validKey.getGaiaAccount(node: validNode, gaiaKey: validKey) { [weak self] account, errMessage in
                self?.loadingView.stopAnimating()
                self?.account = account
                var tmpData: [(denom: String, price: Double, amount: String)] = []
                for touple in self?.dataSource ?? [] {
                    let amount = self?.account?.assets.filter { $0.denom == touple.denom }.first?.amount ?? "0"
                    tmpData.append((denom: touple.denom, price: touple.price, amount: amount))
                }
                self?.dataSource = tmpData
                self?.tableView.reloadData()
            }
        }
    }

    func loadData(validNode: TDMNode) {
        
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        
        loadingView.startAnimating()
        retrieveAllActives(node: validNode) { [weak self] actives, errMsg in
            self?.dataSource = []
            self?.loadingView.stopAnimating()
            if let validActives = actives {
                for active in validActives {
                    dispatchGroup.enter()
                    self?.retrievePrice(node: validNode, active: active) { price, errMsg in
                        if let validprice = price {
                            let dv = Double(validprice.replacingOccurrences(of: "\"", with: "")) ?? 0
                            let amount = self?.account?.assets.filter { $0.denom == active }.first?.amount ?? "0"
                            self?.dataSource.append((active, dv, amount))
                        } else if let validErr = errMsg {
                            self?.toast?.showToastAlert(validErr, autoHideAfter: 15, type: .error, dismissable: true)
                        } else {
                            self?.toast?.showToastAlert("Ooops! I Failed", autoHideAfter: 15, type: .error, dismissable: true)
                        }
                        dispatchGroup.leave()
                    }
                }
            } else if let validErr = errMsg {
                self?.toast?.showToastAlert(validErr, autoHideAfter: 15, type: .error, dismissable: true)
            } else {
                self?.toast?.showToastAlert("Ooops! I Failed", autoHideAfter: 15, type: .error, dismissable: true)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            self.dataSource = self.dataSource.sorted(by: { $0.denom < $1.denom })
            let ulunas = self.account?.assets.filter { $0.denom == validNode.stakeDenom }.first?.amount ?? "0"
            self.dataSource.insert((validNode.stakeDenom, 1.0, ulunas), at: 0)
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
                                        self?.toast?.showToastAlert("Swap successfull", autoHideAfter: 15, type: .info, dismissable: true)
                                        self?.timer = Timer.scheduledTimer(withTimeInterval: 7, repeats: true) { [weak self] timer in
                                            self?.loadAccount()
                                        }
                                    } else if let errMsg = err {
                                        self?.toast?.showToastAlert(errMsg, autoHideAfter: 15, type: .error, dismissable: true)
                                    }
                }
            }
        }
    }
}

extension GaiaOraclesController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GaiaOraclesCellID", for: indexPath) as! GaiaOracleCell
        cell.configure(proposal: dataSource[indexPath.item], baseDenom: node?.stakeDenom ?? "")
        return cell
    }
    
}

extension GaiaOraclesController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tapped = dataSource[indexPath.item]
        DispatchQueue.main.async {
            self.timer?.invalidate()
            if let validOffered = self.offeredDenom {
                self.offeredDenom = nil
                self.toast?.hideToast()
                tableView.reloadData()
                 if validOffered != tapped.denom {
                    self.handleSwap(offerDenom: validOffered, askDenom: tapped.denom)
                }
            } else {
                self.offeredDenom = tapped.denom
                self.toast?.showToastAlert("Pick the denom you want to convert \(tapped.denom) to", type: .validatePending, dismissable: false)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.item == 0 ? 80 : 70
    }
}

class GaiaOracleCell: UITableViewCell {
    
    @IBOutlet weak var roundedView: RoundedView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var priceTitle: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    
    func configure(proposal: (denom: String, price: Double, amount: String), baseDenom: String) {
        let strAmount = String(format: "%.2f", proposal.price)
        nameLabel.text = proposal.denom
        priceLabel.text = strAmount
        amountLabel.text = proposal.amount
        priceTitle.text = "rate / \(baseDenom)"
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        roundedView.backgroundColor = selected ? UIColor(named: "TerraBlueAlpha") : .white
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        roundedView.backgroundColor = highlighted ? UIColor(named: "TerraBlueAlpha") : .white
    }
}
