//
//  GaiaHistoryController.swift
//  Cosmos Client
//
//  Created by kytzu on 23/02/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi

class GaiaHistoryController: UIViewController, ToastAlertViewPresentable, GaiaValidatorsCapable, GaiaKeysManagementCapable {

    var toast: ToastAlertView?
    
    var node: TDMNode?
    var key: GaiaKey?
    var account: GaiaAccount?
    
    @IBOutlet weak var loadingView: CustomLoadingView!
    @IBOutlet weak var toastHolderUnderView: UIView!
    @IBOutlet weak var toastHolderTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var topNavBarView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    var curentPage = 1
    var pageSize = 100
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
        
        loadingView.startAnimating()
        loadData()
    }
    
    func loadData() {
        key?.getTransactions(node: node!, page: curentPage, limit: pageSize) { [weak self] txs, total, err in
            if let transactions = txs, let page = self?.curentPage, let limit = self?.pageSize {
                self?.dataSource.append(contentsOf: transactions)
                self?.dataSource = self?.dataSource.sorted() { $0.height > $1.height } ?? []
                let items = page * limit
                if items < Int(total ?? "0") ?? 0 {
                    self?.curentPage += 1
                    self?.loadData()
                } else {
                    self?.loadingView.stopAnimating()
                    self?.tableView.reloadData()
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
