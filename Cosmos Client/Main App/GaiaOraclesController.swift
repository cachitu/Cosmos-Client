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

    var defaultFeeSigAmount: String { return AppContext.shared.node?.defaultTxFee  ?? "0" }
    
    @IBOutlet weak var loadingView: CustomLoadingView!
    @IBOutlet weak var toastHolderUnderView: UIView!
    @IBOutlet weak var toastHolderTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var topNavBarView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func closeAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    var dataSource: [(denom: String, price: Double, amount: String)] = []
    var offeredDenom: String?  = nil
    private weak var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        toast = createToastAlert(creatorView: view, holderUnderView: toastHolderUnderView, holderTopDistanceConstraint: toastHolderTopConstraint, coveringView: topNavBarView)
        
        let _ = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main) { [weak self] note in
            AppContext.shared.node?.getStatus {
                if AppContext.shared.node?.state == .unknown {
                    self?.dismiss(animated: true, completion: nil)
                } else if let validNode = AppContext.shared.node {
                    self?.loadData(validNode: validNode)
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
                
        if let validNode = AppContext.shared.node {
            loadData(validNode: validNode)
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: GaiaConstants.refreshInterval, repeats: true) { [weak self] timer in
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
    
    private func loadAccount() {
        
        if let validNode = AppContext.shared.node, let validKey = AppContext.shared.key {
            loadingView.startAnimating()
            validKey.getGaiaAccount(node: validNode, gaiaKey: validKey) { [weak self] account, errMessage in
                self?.loadingView.stopAnimating()
                var tmpData: [(denom: String, price: Double, amount: String)] = []
                for touple in self?.dataSource ?? [] {
                    let amount = AppContext.shared.account?.assets.filter { $0.denom == touple.denom }.first?.amount ?? "0"
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
                        let amount = AppContext.shared.account?.assets.filter { $0.denom == active }.first?.amount ?? "0"
                        if let validprice = price {
                            let dv = Double(validprice.replacingOccurrences(of: "\"", with: "")) ?? 0
                            self?.dataSource.append((active, dv, amount))
                        } else if let _ = errMsg {
                            //self?.toast?.showToastAlert(validErr, autoHideAfter: GaiaConstants.autoHideToastTime, type: .error, dismissable: true)
                            self?.dataSource.append((active, 0, amount))
                        } else {
                            //self?.toast?.showToastAlert("Ooops! I Failed", autoHideAfter: GaiaConstants.autoHideToastTime, type: .error, dismissable: true)
                            self?.dataSource.append((active, 0, amount))
                        }
                        dispatchGroup.leave()
                    }
                }
            } else if let validErr = errMsg {
                self?.toast?.showToastAlert(validErr, autoHideAfter: GaiaConstants.autoHideToastTime, type: .error, dismissable: true)
            } else {
                self?.toast?.showToastAlert("Ooops! I Failed", autoHideAfter: GaiaConstants.autoHideToastTime, type: .error, dismissable: true)
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            self.dataSource = self.dataSource.sorted(by: { $0.denom < $1.denom })
            let ulunas = AppContext.shared.account?.assets.filter { $0.denom == validNode.stakeDenom }.first?.amount ?? "0"
            self.dataSource.insert((validNode.stakeDenom, 1.0, ulunas), at: 0)
            self.tableView.reloadData()
        }
    }
    
    private func handleSwap(offerDenom: String, askDenom: String) {
        
        print("Should swap to \(askDenom)")
        showAmountAlert(title: "Type the amount of \(offerDenom) you want to swap to \(askDenom)", message: "", placeholder: "0 \(offerDenom)") { amount in
            if let validAmount = amount, let validNode = AppContext.shared.node, let validKey = AppContext.shared.key, let delegate = AppContext.shared.keysDelegate {
                self.loadingView.startAnimating()
                self.swapActives(node: validNode,
                                 clientDelegate: delegate,
                                 key: validKey,
                                 offerAmount: validAmount,
                                 offerDenom: offerDenom,
                                 askDenom: askDenom,
                                 feeAmount: self.defaultFeeSigAmount) { [weak self] resp, msg in
                                    self?.loadingView.stopAnimating()
                                    if resp != nil {
                                        self?.toast?.showToastAlert("Swap submitted\n[\(msg ?? "...")]", autoHideAfter: GaiaConstants.autoHideToastTime, type: .validatePending, dismissable: true)
                                        self?.timer = Timer.scheduledTimer(withTimeInterval: GaiaConstants.refreshInterval, repeats: true) { [weak self] timer in
                                            self?.loadAccount()
                                        }
                                    } else if let errMsg = msg {
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
}

extension GaiaOraclesController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GaiaOraclesCellID", for: indexPath) as! GaiaOracleCell
        cell.configure(proposal: dataSource[indexPath.item], baseDenom: AppContext.shared.node?.stakeDenom ?? "")
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
        priceLabel.text = strAmount == "0.00" ? "?" : strAmount
        amountLabel.text = proposal.amount
        priceTitle.text = "rate / \(baseDenom)"
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        roundedView.backgroundColor = selected ? .cellBackgroundColorAlpha : .cellBackgroundColor
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        roundedView.backgroundColor = highlighted ? .cellBackgroundColorAlpha : .cellBackgroundColor
    }
}
