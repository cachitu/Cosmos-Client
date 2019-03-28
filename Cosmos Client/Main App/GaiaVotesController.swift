//
//  GaiaVotesController.swift
//  Cosmos Client
//
//  Created by kytzu on 28/03/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi

//class GaiaVotesController: UIViewController {
class GaiaVotesController: UIViewController, ToastAlertViewPresentable, GaiaKeysManagementCapable {
    
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
    
    var dataSource: [ProposalVote] = []
    
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
    }
    
    @IBAction func closeAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
}

extension GaiaVotesController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GaiaKeyCellID", for: indexPath) as! GaiaKeyCell
        let delegation = dataSource[indexPath.item]
        cell.leftLabel.text    = delegation.option
        cell.leftSubLabel.text = delegation.voter
        return cell
    }
}
