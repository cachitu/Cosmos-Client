//
//  GaiaGovernanceController.swift
//  Cosmos Client
//
//  Created by Calin Chitu on 14/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi

class GaiaGovernanceController: UIViewController, ToastAlertViewPresentable, GaiaGovernaceCapable {

    var toast: ToastAlertView?

    var node: GaiaNode?
    var key: GaiaKey?
    var account: GaiaAccount?

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
    
    var dataSource: [GaiaProposal] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        toast = createToastAlert(creatorView: view, holderUnderView: toastHolderUnderView, holderTopDistanceConstraint: toastHolderTopConstraint, coveringView: topNavBarView)
        bottomTabbarView.onTap = { [weak self] index in
            switch index {
            case 0:
                self?.onUnwind?(0)
                self?.performSegue(withIdentifier: "UnwindToWallet", sender: nil)
            case 1: self?.dismiss(animated: true)
            case 3: self?.performSegue(withIdentifier: "nextSegue", sender: index)
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
        
        bottomTabbarView.selectIndex(2)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !lockLifeCicleDelegates else {
            lockLifeCicleDelegates = false
            return
        }
        if forwardCounter > 0 {
            UIView.setAnimationsEnabled(true)
            self.performSegue(withIdentifier: "nextSegue", sender: 3)
            forwardCounter = 0
            return
        }
        
        if let validNode = node {
            loadingView.startAnimating()
            retrieveAllPropsals(node: validNode) { [weak self] proposals, errMsg in
                self?.loadingView.stopAnimating()
                if let validProposals = proposals {
                    self?.dataSource = validProposals
                    self?.tableView.reloadData()
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
            let dest = segue.destination as? GaiaTransactionsController
            dest?.forwardCounter = index - 3
            dest?.onUnwind = { [weak self] index in
                self?.lockLifeCicleDelegates = true
                self?.bottomTabbarView.selectIndex(-1)
                if index == 0 { self?.onUnwind?(index) }
            }
            forwardCounter = 0
        }
    }

    @IBAction func unwindToGovernance(segue:UIStoryboardSegue) {
        bottomTabbarView.selectIndex(2)
    }

}

extension GaiaGovernanceController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GaiaGovernanceCellID", for: indexPath) as! GaiaGovernanceCell
        let proposal = dataSource[indexPath.item]
        cell.configure(proposal: proposal)
        return cell
    }
    
}
