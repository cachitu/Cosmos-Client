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

    var defaultFeeSigAmount: String { return AppContext.shared.node?.defaultTxFee  ?? "0" }
    var selectedProposal: GaiaProposal?
    
    @IBOutlet weak var loadingView: CustomLoadingView!
    @IBOutlet weak var toastHolderUnderView: UIView!
    @IBOutlet weak var toastHolderTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var topNavBarView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addButton: UIButton!
    
    @IBOutlet weak var logsButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var logsButton: RoundedButton!
    @IBAction func logsAction(_ sender: UIButton) {
    }

    var dataSource: [GaiaProposal] = []
    var proposeData: ProposalData?
    private weak var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        addButton.layer.cornerRadius = addButton.frame.size.height / 2
        addButton.isHidden = AppContext.shared.key?.watchMode == true
        toast = createToastAlert(creatorView: view, holderUnderView: toastHolderUnderView, holderTopDistanceConstraint: toastHolderTopConstraint, coveringView: topNavBarView)
        
        let _ = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main) { [weak self] note in
            AppContext.shared.node?.getStatus {
                if AppContext.shared.node?.state == .unknown {
                    self?.performSegue(withIdentifier: "UnwindToNodes", sender: self)
                } else if let validNode = AppContext.shared.node {
                    self?.loadData(validNode: validNode)
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.logsButton.backgroundColor = UIColor.pendingYellow
        AppContext.shared.onHashPolingPending = {
            guard AppContext.shared.key?.watchMode == false else {
                return
            }
            self.logsButtonBottomConstraint.constant = 8
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
        }
        AppContext.shared.onHashPolingDone = {
            self.logsButtonBottomConstraint.constant = -50
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
        }
        if let hash = AppContext.shared.lastSubmitedHash() {
            AppContext.shared.startHashPoling(hash: hash)
        } else {
            self.logsButtonBottomConstraint.constant = -50
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let data = proposeData {
            if AppContext.shared.node?.secured == true, let tabBar = tabBarController as? GaiaTabBarController {
                tabBar.onSecurityCheck = { [weak self] succes in
                    if succes {
                        self?.createProposal(data: data)
                    } else {
                        self?.toast?.showToastAlert("The pin you entered is incorrect. Please try again.",  type: .error, dismissable: true)
                    }
                }
                tabBar.promptForPin()
            } else {
                createProposal(data: data)
            }
        } else if let validNode = AppContext.shared.node {
            loadData(validNode: validNode, showLoader: true)
        }
        timer = Timer.scheduledTimer(withTimeInterval: GaiaConstants.refreshInterval, repeats: true) { [weak self] timer in
            if let validNode = AppContext.shared.node {
                self?.loadData(validNode: validNode)
            }
        }

        proposeData = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "VotesSegueID" {
            
            let dest = segue.destination as? GaiaVotesController
            dest?.dataSource = selectedProposal?.votes ?? []
            
        } else if segue.identifier == "CreateProposalSegueID" {
            
            guard let dest = segue.destination as? GaiaProposalController else { return }
            dest.onCollectDataComplete = { [weak self] data in
                self?.proposeData = data
            }
        }
    }

    func loadData(validNode: TDMNode, showLoader: Bool = false) {
        
        if let hash = AppContext.shared.lastSubmitedHash() {
            AppContext.shared.startHashPoling(hash: hash)
        }

        let dispatchGroup = DispatchGroup()

        if showLoader { loadingView.startAnimating() }
        retrieveAllPropsals(node: validNode) { [weak self] proposals, error in
            var tmpDataSource: [GaiaProposal] = []
            if let validProposals = proposals {
                if validProposals.count > 0 {
                    for proposal in validProposals {
                        dispatchGroup.enter()
                        self?.getPropsalDetails(node: validNode, proposal: proposal) { detailedProposal, error in
                            if let valid = detailedProposal {
                                tmpDataSource.append(valid)
                                dispatchGroup.leave()
                            } else {
                                tmpDataSource.append(proposal)
                                dispatchGroup.leave()
                            }
                        }
                    }
                    
                    dispatchGroup.notify(queue: .main) {
                        self?.loadingView.stopAnimating()
                        self?.dataSource = tmpDataSource.sorted() { $0.proposalId > $1.proposalId }
                        self?.tableView.reloadData()
                    }


                } else {
                    self?.loadingView.stopAnimating()
                    self?.toast?.showToastAlert("There are no proposals available", autoHideAfter: GaiaConstants.autoHideToastTime, type: .info, dismissable: true)
                }
            } else if let errMsg = error {
                self?.loadingView.stopAnimating()
                if errMsg.contains("connection was lost") {
                    self?.toast?.showToastAlert("Tx broadcasted but not confirmed yet", autoHideAfter: GaiaConstants.autoHideToastTime, type: .validatePending, dismissable: true)
                } else {
                    self?.toast?.showToastAlert(errMsg, autoHideAfter: GaiaConstants.autoHideToastTime, type: .error, dismissable: true)
                }
            } else {
                self?.loadingView.stopAnimating()
                self?.toast?.showToastAlert("Ooops! I Failed", autoHideAfter: GaiaConstants.autoHideToastTime, type: .error, dismissable: true)
            }
        }
    }
    
    @IBAction func unwindToGovernance(segue:UIStoryboardSegue) {
    }

    func createProposal(data: ProposalData) {
        if let node = AppContext.shared.node, let key = AppContext.shared.key, let keysDelegate = AppContext.shared.keysDelegate {
            self.loadingView.startAnimating()
            self.toast?.showToastAlert("Proposal create request submited", autoHideAfter: GaiaConstants.autoHideToastTime, type: .validatePending, dismissable: true)
            self.propose(
                deposit: data.amount,
                title: data.title,
                description: data.description,
                type: data.type,
                node: node,
                clientDelegate: keysDelegate,
                key: key,
                feeAmount: self.defaultFeeSigAmount) { [weak self] resp, msg in
                    self?.loadingView.stopAnimating()
                    if resp != nil {
                        self?.toast?.showToastAlert("Proposal Create submitted\n[\(msg ?? "...")]", autoHideAfter: GaiaConstants.autoHideToastTime, type: .validatePending, dismissable: true)
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
    
    func handleVoting(proposal: GaiaProposal) {
        self.showVotingAlert(title: proposal.title, message: proposal.description) { [weak self] voteStr in
            
            if AppContext.shared.node?.secured == true, let tabBar = self?.tabBarController as? GaiaTabBarController {
                tabBar.onSecurityCheck = { [weak self] succes in
                    if succes {
                        self?.broadcastVoting(proposal: proposal, voteStr: voteStr)
                    } else {
                        self?.toast?.showToastAlert("The pin you entered is incorrect. Please try again.",  type: .error, dismissable: true)
                    }
                }
                tabBar.promptForPin()
            } else {
                self?.broadcastVoting(proposal: proposal, voteStr: voteStr)
            }
        }
    }
    
    func broadcastVoting(proposal: GaiaProposal, voteStr: String?) {
        guard let voteOpt = voteStr, let node = AppContext.shared.node, let key = AppContext.shared.key, let delegate = AppContext.shared.keysDelegate  else { return }
        
        loadingView.startAnimating()
        vote(
            for: proposal.proposalId,
            option: voteOpt,
            node: node,
            clientDelegate: delegate,
            key: key,
            feeAmount: defaultFeeSigAmount)
        {  [weak self] resp, msg in
            self?.loadingView.stopAnimating()
            if resp != nil {
                self?.toast?.showToastAlert("Vote submitted\n[\(msg ?? "...")]", autoHideAfter: GaiaConstants.autoHideToastTime, type: .validatePending, dismissable: true)
                if let hash = AppContext.shared.lastSubmitedHash() {
                    AppContext.shared.startHashPoling(hash: hash)
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
    
    func handleDeposit(proposal: GaiaProposal) {
        let denom = AppContext.shared.node?.stakeDenom ?? "stake"
        showAmountAlert(title: "Type the amount of \(denom) you want to deposit to proposal with id \(proposal.proposalId)", message: nil, placeholder: "0 \(denom)") { [weak self] amount in
            
            if AppContext.shared.node?.secured == true, let tabBar = self?.tabBarController as? GaiaTabBarController {
                tabBar.onSecurityCheck = { [weak self] succes in
                    if succes {
                        self?.broadcastDeposit(proposal: proposal, amount: amount ?? "")
                    } else {
                        self?.toast?.showToastAlert("The pin you entered is incorrect. Please try again.",  type: .error, dismissable: true)
                    }
                }
                tabBar.promptForPin()
            } else {
                self?.broadcastDeposit(proposal: proposal, amount: amount ?? "")
            }
        }
    }
    
    func broadcastDeposit(proposal: GaiaProposal, amount: String) {
        guard let node = AppContext.shared.node, let key = AppContext.shared.key, let delegate = AppContext.shared.keysDelegate  else { return }
        loadingView.startAnimating()
        depositToProposal(
            proposalId: proposal.proposalId,
            amount: amount,
            node: node,
            clientDelegate: delegate,
            key: key,
            feeAmount: defaultFeeSigAmount) { [weak self] resp, msg in
                self?.loadingView.stopAnimating()
                if resp != nil {
                    self?.toast?.showToastAlert("Deposit submitted\n[\(msg ?? "...")]", autoHideAfter: GaiaConstants.autoHideToastTime, type: .validatePending, dismissable: true)
                    if let hash = AppContext.shared.lastSubmitedHash() {
                        AppContext.shared.startHashPoling(hash: hash)
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

extension GaiaGovernanceController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GaiaGovernanceCellID", for: indexPath) as! GaiaGovernanceCell
        let proposal = dataSource[indexPath.item]
        cell.configure(proposal: proposal, voter: AppContext.shared.account, image: AppContext.shared.node?.nodeLogoWhite)
        return cell
    }
    
}

extension GaiaGovernanceController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let proposal = dataSource[indexPath.item]
        selectedProposal = proposal
        
        DispatchQueue.main.async {
            
            let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            let votesAction = UIAlertAction(title: "View Votes", style: .default) { [weak self] alertAction in
                self?.performSegue(withIdentifier: "VotesSegueID", sender: self)
            }
            
            let detailsAction = UIAlertAction(title: "Details", style: .default) { [weak self] alertAction in
                self?.showProposalDetailsAlert(title: proposal.title, message: proposal.description)
            }
            
            let voteAction = UIAlertAction(title: "Submit Vote", style: .default) { [weak self] alertAction in
                self?.handleVoting(proposal: proposal)
            }
            
            let depositAction = UIAlertAction(title: "Add Deposit", style: .default) { [weak self] alertAction in
                self?.handleDeposit(proposal: proposal)
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            let editable =  AppContext.shared.key?.watchMode != true
            
            switch (proposal.status, editable) {
            case ("Passed", true)  :
                optionMenu.addAction(votesAction)
            case ("Rejected", true) :
                optionMenu.addAction(votesAction)
            case ("DepositPeriod", true) :
                optionMenu.addAction(depositAction)
            default:
                if editable { optionMenu.addAction(voteAction) }
                optionMenu.addAction(votesAction)
            }

            optionMenu.addAction(detailsAction)
            optionMenu.addAction(cancelAction)
            
            self.present(optionMenu, animated: true, completion: nil)
        }
    }
}
