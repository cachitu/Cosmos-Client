//
//  GaiaHashesController.swift
//  Syncnode
//
//  Created by Calin Chitu on 12/27/19.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi

class GaiaHashesController: UIViewController, ToastAlertViewPresentable, GaiaValidatorsCapable, GaiaKeysManagementCapable {

    var toast: ToastAlertView?
    
    var validator: GaiaValidator?
    
    @IBOutlet weak var loadingView: CustomLoadingView!
    @IBOutlet weak var toastHolderUnderView: UIView!
    @IBOutlet weak var toastHolderTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var topNavBarView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func clearAction(_ sender: UIButton) {
        AppContext.shared.clearHashes()
        dataSource = AppContext.shared.hashes
        tableView.reloadData()
        self.dismiss(animated: true)
    }
    
    var dataSource: [PersitsableHash] = AppContext.shared.hashes
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toast = createToastAlert(creatorView: view, holderUnderView: toastHolderUnderView, holderTopDistanceConstraint: toastHolderTopConstraint, coveringView: topNavBarView)
        
        let _ = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main) { [weak self] note in
            AppContext.shared.node?.getStatus {
                if AppContext.shared.node?.state == .unknown {
                    self?.performSegue(withIdentifier: "UnwindToNodes", sender: self)
                } else {
                    self?.dataSource = AppContext.shared.hashes
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func closeAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    func getFormattedDate(date: Date, format: String) -> String {
            let dateformat = DateFormatter()
            dateformat.dateFormat = format
            return dateformat.string(from: date)
    }

}

extension GaiaHashesController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GaiaHashCellID", for: indexPath) as? GaiaHashCell
        let hash = dataSource[indexPath.item]
        let formatingDate = getFormattedDate(date: hash.date, format: "dd/MM/yy - HH:mm:ss")

        cell?.leftLabel.text = "Submit date: \(formatingDate)"
        cell?.leftSubLabel.text = hash.hash
        cell?.leftIconImageView.image = AppContext.shared.node?.nodeLogoWhite
        return cell ?? UITableViewCell()
    }
}

extension GaiaHashesController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let hash = dataSource[indexPath.item]
        loadingView.startAnimating()
        tableView.allowsSelection = false
        AppContext.shared.key?.getHash(node: AppContext.shared.node!, gaiaKey: AppContext.shared.key!, hash: hash.hash) { [weak self] resp, msg in
            DispatchQueue.main.async {
                tableView.allowsSelection = true
                self?.loadingView.stopAnimating()
                if let valid = resp {
                    
                    let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                    let shareHashAction = UIAlertAction(title: "Share Hash", style: .default) { [weak self] alertAction in
                        let textShare = [ hash.hash ]
                        let activityViewController = UIActivityViewController(activityItems: textShare , applicationActivities: nil)
                        activityViewController.popoverPresentationController?.sourceView = self?.view
                        self?.present(activityViewController, animated: true, completion: nil)
                    }
                    let shareAction = UIAlertAction(title: "Share Log", style: .default) { [weak self] alertAction in
                        let textShare = [ valid.rawLog ]
                        let activityViewController = UIActivityViewController(activityItems: textShare , applicationActivities: nil)
                        activityViewController.popoverPresentationController?.sourceView = self?.view
                        self?.present(activityViewController, animated: true, completion: nil)
                    }
                    let viewAction = UIAlertAction(title: "View Log", style: .default) { [weak self] alertAction in
                        self?.showProposalDetailsAlert(title: nil, message: valid.rawLog.data(using: .utf8)?.prettyPrintedJSONString)
                    }
                    
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                    
                    optionMenu.addAction(shareHashAction)
                    optionMenu.addAction(shareAction)
                    optionMenu.addAction(viewAction)
                    optionMenu.addAction(cancelAction)
                    
                    self?.present(optionMenu, animated: true, completion: nil)

                    print(valid.rawLog)
                } else {
                    self?.toast?.showToastAlert("The hash has not been found yet, try again in a few seconds.", autoHideAfter: GaiaConstants.autoHideToastTime, type: .validatePending, dismissable: true)
                }
            }
        }
    }
}

class GaiaHashCell: UITableViewCell {

    @IBOutlet weak var leftLabel: UILabel!
    @IBOutlet weak var leftSubLabel: UILabel!
    @IBOutlet weak var leftIconImageView: UIImageView!
    
}
