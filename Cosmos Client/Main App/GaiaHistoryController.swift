//
//  GaiaHistoryController.swift
//  Cosmos Client
//
//  Created by kytzu on 23/02/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi

class PersistableHistory: PersistCodable {
    
    let transactions: [GaiaTransaction]
    
    init(transactions: [GaiaTransaction]) {
        self.transactions = transactions
    }
}

class GaiaHistoryController: UIViewController, ToastAlertViewPresentable, GaiaValidatorsCapable, GaiaKeysManagementCapable {

    var toast: ToastAlertView?
    
    var node: TDMNode?
    var key: GaiaKey?
    var account: GaiaAccount?
    
    var storeUID: String {
        let addr = key?.address ?? ""
        let nodeID = node?.nodeID ?? ""
        return "_" + nodeID + "-" + addr
    }
    
    @IBOutlet weak var loadingView: CustomLoadingView!
    @IBOutlet weak var toastHolderUnderView: UIView!
    @IBOutlet weak var toastHolderTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var topNavBarView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func clearAction(_ sender: Any) {
        dataSource = []
        tableView.reloadData()
        PersistableHistory(transactions: dataSource).savetoDisk(withUID: storeUID)
        dismiss(animated: true, completion: nil)
    }
    
    var curentSentPage = 1
    var curentReceivedPage = 1

    var dataSource: [GaiaTransaction] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toast = createToastAlert(creatorView: view, holderUnderView: toastHolderUnderView, holderTopDistanceConstraint: toastHolderTopConstraint, coveringView: topNavBarView)
        
        let _ = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main) { [weak self] note in
            self?.node?.getStatus {
                if self?.node?.state == .unknown {
                    self?.performSegue(withIdentifier: "UnwindToNodes", sender: self)
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let savedHistory = PersistableHistory.loadFromDisk(withUID: storeUID) as? PersistableHistory {
            self.getRemoteCount { [weak self] sent, received in
                let total = (sent + received)
                if total != savedHistory.transactions.count {
//
//                    let delta    = total - savedHistory.transactions.count
//                    let spages   = (sent + GaiaConstants.historyPageSize - 1) / GaiaConstants.historyPageSize
//                    let rpages   = (received + GaiaConstants.historyPageSize - 1) / GaiaConstants.historyPageSize
//                    let newPages = (delta + GaiaConstants.historyPageSize - 1) / GaiaConstants.historyPageSize
//                    self?.curentSentPage     = (spages - newPages) > 1 ? min(spages, spages - newPages) : 1
//                    self?.curentReceivedPage = (rpages - newPages) > 1 ? min(rpages, rpages - newPages) : 1
//                    self?.dataSource = savedHistory.transactions
                    self?.loadingView.startAnimating()
                    self?.loadData()
                    
                } else {

                    DispatchQueue.main.async {
                        self?.loadingView.stopAnimating()
                        self?.dataSource = savedHistory.transactions
                        self?.tableView.reloadData()
                        self?.toast?.showToastAlert("You have \(total) transactions in history 🐱", autoHideAfter: 3, type: .validatePending, dismissable: true)
                    }
                }
            }
        } else {
            loadingView.startAnimating()
            loadData()
        }
    }
    
    func getRemoteCount(completion: @escaping ((_ sentTotal: Int, _ receivedTotal: Int) -> ())) {
        var sentItems = 0
        var receivedItems = 0
        loadingView.startAnimating()
        key?.getSentTransactions(node: node!, page: 1, limit: 1) { [weak self] txs, total, err in
            sentItems = Int(total ?? "0") ?? 0
            self?.key?.getReceivedTransactions(node: (self?.node)!, page: 1, limit: 1) { txs, total, err in
                receivedItems = Int(total ?? "0") ?? 0
                completion(sentItems, receivedItems)
            }
        }
    }
    

    func loadData(removeDuplicates: Bool = false) {
        print("get sent page \(curentSentPage)")
        //toast?.showToastAlert("Getting sent items page \(curentSentPage) 🐱", autoHideAfter: 3, type: .validatePending, dismissable: true)
        key?.getSentTransactions(node: node!, page: curentSentPage, limit: GaiaConstants.historyPageSize) { [weak self] txs, total, err in
            if let transactions = txs, let page = self?.curentSentPage {
                self?.dataSource.append(contentsOf: transactions)
                let items = page * GaiaConstants.historyPageSize
                if items < Int(total ?? "0") ?? 0 {
                    self?.curentSentPage += 1
                    self?.loadData(removeDuplicates: removeDuplicates)
                } else {
                    self?.getReceivedTx(removeDuplicates: removeDuplicates)
                }
            } else if let validErr = err {
                self?.loadingView.stopAnimating()
                self?.toast?.showToastAlert(validErr, autoHideAfter: 15, type: .error, dismissable: true)
            } else {
                self?.loadingView.stopAnimating()
                self?.toast?.showToastAlert("Ooops! I Failed", autoHideAfter: 15, type: .error, dismissable: true)
            }
        }
    }

    func getReceivedTx(removeDuplicates: Bool = false) {
        print("get received page \(curentReceivedPage)")
        //toast?.showToastAlert("Getting received items page \(curentReceivedPage) 🐱", autoHideAfter: 3, type: .validatePending, dismissable: true)
        key?.getReceivedTransactions(node: node!, page: curentReceivedPage, limit: GaiaConstants.historyPageSize) { [weak self] txs, total, err in
            if let transactions = txs, let page = self?.curentReceivedPage {
                self?.dataSource.append(contentsOf: transactions)
                let items = page * GaiaConstants.historyPageSize
                if items < Int(total ?? "0") ?? 0 {
                    self?.curentReceivedPage += 1
                    self?.getReceivedTx(removeDuplicates: removeDuplicates)
                } else {
                    if removeDuplicates {
                        self?.dataSource = self?.dataSource.uniqued() ?? []
                    }
                    self?.dataSource = self?.dataSource.sorted() { $0.height > $1.height } ?? []
                    if let items = self?.dataSource {
                        PersistableHistory(transactions: items).savetoDisk(withUID: self?.storeUID ?? "")
                    }
                    self?.loadingView.stopAnimating()
                    self?.tableView.reloadData()
                    self?.toast?.showToastAlert("You have \(self?.dataSource.count ?? 0) transactions in history 🐱", autoHideAfter: 3, type: .validatePending, dismissable: true)
                }
            } else if let validErr = err {
                self?.loadingView.stopAnimating()
                self?.toast?.showToastAlert(validErr, autoHideAfter: 15, type: .error, dismissable: true)
            } else {
                self?.loadingView.stopAnimating()
                self?.toast?.showToastAlert("Ooops! I Failed", autoHideAfter: 15, type: .error, dismissable: true)
            }
        }
    }
    
    @IBAction func closeAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
}

extension GaiaHistoryController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GaiaHistoryCellID", for: indexPath) as! GaiaHistoryCell
        let transaction = dataSource[indexPath.item]
        cell.configure(tx: transaction, ownerAddr: key?.address ?? "")
        return cell
    }
    
}

extension GaiaHistoryController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let tx = dataSource[indexPath.item]
        DispatchQueue.main.async {

            let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let shareHashAction = UIAlertAction(title: "Share Hash", style: .default) { [weak self] alertAction in
                let textShare = [ tx.hash ]
                let activityViewController = UIActivityViewController(activityItems: textShare , applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = self?.view
                self?.present(activityViewController, animated: true, completion: nil)
            }
            let shareAction = UIAlertAction(title: "Share Log", style: .default) { [weak self] alertAction in
                let textShare = [ tx.rawLog ]
                let activityViewController = UIActivityViewController(activityItems: textShare , applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = self?.view
                self?.present(activityViewController, animated: true, completion: nil)
            }
            let viewAction = UIAlertAction(title: "View Log", style: .default) { [weak self] alertAction in
                self?.showProposalDetailsAlert(title: nil, message: tx.rawLog.data(using: .utf8)?.prettyPrintedJSONString)
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            optionMenu.addAction(shareHashAction)
            optionMenu.addAction(shareAction)
            optionMenu.addAction(viewAction)
            optionMenu.addAction(cancelAction)
            
            self.present(optionMenu, animated: true, completion: nil)
        }
    }
}

extension Data {
    var prettyPrintedJSONString: String? { /// NSString gives us a nice sanitized debugDescription
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
            let prettyPrintedString = String(data: data, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue)) else { return nil }

        return prettyPrintedString
    }
}

extension Array where Element: Hashable {
    
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter{ seen.insert($0).inserted }
    }
    
    func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()

        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }

    mutating func removeDuplicates() {
        self = self.removingDuplicates()
    }
}
