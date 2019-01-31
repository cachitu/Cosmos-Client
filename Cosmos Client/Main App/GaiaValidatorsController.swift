//
//  GaiaValidatorsController.swift
//  Cosmos Client
//
//  Created by Calin Chitu on 14/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi

class GaiaValidatorsController: UIViewController, ToastAlertViewPresentable, GaiaValidatorsCapable {
    
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

    var dataSource: [GaiaValidator] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        toast = createToastAlert(creatorView: view, holderUnderView: toastHolderUnderView, holderTopDistanceConstraint: toastHolderTopConstraint, coveringView: topNavBarView)
        bottomTabbarView.onTap = { index in
            switch index {
            case 0: self.dismiss(animated: true)
            case 2: self.performSegue(withIdentifier: "nextSegue", sender: index)
            case 3:
                self.performSegue(withIdentifier: "nextSegue", sender: index)
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
        
        if let validNode = node {
            loadingView.startAnimating()
            retrieveAllValidators(node: validNode) { validators, errMsg in
                self.loadingView.stopAnimating()
                if let validvalidators = validators {
                    self.dataSource = validvalidators.sorted() { (left, right) -> Bool in
                        left.votingPower > right.votingPower
                    }
                    self.tableView.reloadData()
                } else if let validErr = errMsg {
                    self.toast?.showToastAlert(validErr, autoHideAfter: 5, type: .error, dismissable: true)
                } else {
                    self.toast?.showToastAlert("Ooops! I Failed", autoHideAfter: 5, type: .error, dismissable: true)
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
            dest?.onUnwind = { index in
                self.bottomTabbarView.selectIndex(-1)
                self.lockLifeCicleDelegates = true
            }
            forwardCounter = 0
        }
    }

    @IBAction func unwindToValidator(segue:UIStoryboardSegue) {
        bottomTabbarView.selectIndex(1)
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
        guard let validNode = node, let validKey = key, validator.jailed == true else { return }
        loadingView.startAnimating()
        validator.unjail(node: validNode, key: validKey) { resp, errMsg in
            self.loadingView.stopAnimating()
            if let msg = errMsg {
                self.toast?.showToastAlert(msg, autoHideAfter: 3, type: .error, dismissable: true)
            } else  {
                self.toast?.showToastAlert("Unjail request submited", autoHideAfter: 3, type: .info, dismissable: true)
                self.tableView.reloadData()
            }
        }
    }
}
