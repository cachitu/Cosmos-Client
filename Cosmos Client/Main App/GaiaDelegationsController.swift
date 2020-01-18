//
//  GaiaDelegationsController.swift
//  Cosmos Client
//
//  Created by kytzu on 24/02/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi

class GaiaDelegationsController: UIViewController, ToastAlertViewPresentable, GaiaValidatorsCapable, GaiaKeysManagementCapable {

    var toast: ToastAlertView?
    
    var validator: GaiaValidator?
    
    @IBOutlet weak var loadingView: CustomLoadingView!
    @IBOutlet weak var toastHolderUnderView: UIView!
    @IBOutlet weak var toastHolderTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var topNavBarView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    var dataSource: [GaiaDelegation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toast = createToastAlert(creatorView: view, holderUnderView: toastHolderUnderView, holderTopDistanceConstraint: toastHolderTopConstraint, coveringView: topNavBarView)
        
        let _ = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main) { [weak self] note in
            guard !AppContext.shared.collectScreenOpen else { return }
            AppContext.shared.node?.getStatus {
                if AppContext.shared.node?.state == .unknown {
                    self?.performSegue(withIdentifier: "UnwindToNodes", sender: self)
                } else {
                    self?.loadData()
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        loadData()
    }
    
    func loadData() {
        self.loadingView.startAnimating()
        
        if let validNode = AppContext.shared.node, let validValidator = validator {
            validValidator.getValidatorDelegations(node: validNode) { [weak self] delegations, error in
                self?.loadingView.stopAnimating()
                if let validDelegations = delegations {
                    self?.dataSource = validDelegations
                    self?.tableView.reloadData()
                } else if let validErr = error {
                    self?.toast?.showToastAlert(validErr, type: .error, dismissable: true)
                } else {
                    self?.toast?.showToastAlert("Ooops! I Failed", autoHideAfter: GaiaConstants.autoHideToastTime, type: .error, dismissable: true)
                }
            }
        } else {
            self.loadingView.stopAnimating()
        }
    }
    
    @IBAction func closeAction(_ sender: Any) {
        self.dismiss(animated: true)
    }

}

extension GaiaDelegationsController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GaiaDelegationCellID", for: indexPath) as? GaiaDelegationCell
        let delegation = dataSource[indexPath.item]
        let parts = delegation.shares.split(separator: ".")
        cell?.leftLabel.text = "\(parts.first ?? "0") shares from"
        cell?.leftSubLabel.text = delegation.delegatorAddr
        return cell ?? UITableViewCell()
    }
}

extension GaiaDelegationsController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let delegation = dataSource[indexPath.item]
        DispatchQueue.main.async {
            let text = "\(delegation.delegatorAddr)"
            let textShare = [ text ]
            let activityViewController = UIActivityViewController(activityItems: textShare , applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view
            self.present(activityViewController, animated: true, completion: nil)
        }
    }
}

class GaiaDelegationCell: UITableViewCell {

    @IBOutlet weak var leftLabel: UILabel!
    @IBOutlet weak var leftSubLabel: UILabel!
    @IBOutlet weak var upRightLabel: UILabel?
    
    @IBAction func copyAction(_ sender: Any) {
        UIPasteboard.general.string = leftSubLabel.text
        onCopy?()
    }
    
    var onCopy:(() -> ())?
    
    func configure(key: GaiaKey, amount: String = "") {
        upRightLabel?.text = amount
        leftLabel.text = key.name
        leftSubLabel.text = key.address
    }
}
