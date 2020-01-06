//
//  GaiaNodesController.swift
//  Cosmos Client
//
//  Created by Calin Chitu on 12/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi

class PersistableGaiaNodes: PersistCodable {
    
    let nodes: [TDMNode]
    
    init(nodes: [TDMNode]) {
        self.nodes = nodes
    }
}

class GaiaNodesController: UIViewController, ToastAlertViewPresentable {
    
    var toast: ToastAlertView?
    
    @IBOutlet weak var loadingView: CustomLoadingView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noDataView: UIView!
    @IBOutlet weak var toastHolderUnderView: UIView!
    @IBOutlet weak var toastHolderTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var topNavBarView: UIView!
    @IBOutlet weak var addButton: UIButton!
    @IBAction func unwindToNodes(segue:UIStoryboardSegue) { }
    
    @IBOutlet weak var editButton: UIButton!
    @IBAction func editButtonAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        tableView.setEditing(sender.isSelected, animated: true)
    }
    
    var addressBook: GaiaAddressBook = GaiaAddressBook(items: [])
    
    fileprivate var nodes: [TDMNode] =  []
    fileprivate weak var selectedNode: TDMNode?
    fileprivate var selectedIndex: Int = 0
    
    private weak var timer: Timer?
    private var showHint = true
    private var shouldReloadData = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toast = createToastAlert(creatorView: view, holderUnderView: toastHolderUnderView, holderTopDistanceConstraint: toastHolderTopConstraint, coveringView: topNavBarView)
        addButton.layer.cornerRadius = addButton.frame.size.height / 2
        if let savedNodes = PersistableGaiaNodes.loadFromDisk() as? PersistableGaiaNodes {
            nodes = savedNodes.nodes
            showHint = false
            for node in nodes {
                node.state = .pending
            }
        } else {
            nodes = [
                TDMNode(name: TDMNodeType.cosmos.rawValue, type: .cosmos, scheme: "http", host: "wallet01.syncnode.ro", rcpPort: 1317, secured: true),
                TDMNode(name: TDMNodeType.iris.rawValue,  type: .iris,scheme: "http", host: "wallet01.syncnode.ro", rcpPort: 1327, secured: true),
                TDMNode(name: TDMNodeType.terra.rawValue,  type: .terra,scheme: "http", host: "wallet01.syncnode.ro", rcpPort: 1337, secured: true),
                TDMNode(name: TDMNodeType.kava.rawValue,  type: .kava,scheme: "http", host: "wallet01.syncnode.ro", rcpPort: 1347, secured: true),
                TDMNode(name: TDMNodeType.terra.rawValue + " (Old HD)",  type: .terra_118,scheme: "http", host: "wallet01.syncnode.ro", rcpPort: 1337, secured: true),
                TDMNode(name: "Iris Nyancat Testnet",  type: .iris_fuxi,scheme: "http", host: "testwallet.syncnode.ro", rcpPort: 1337, secured: false),
                TDMNode(name: "Cosmos testnet",  type: .cosmos,scheme: "http", host: "testwallet.syncnode.ro", rcpPort: 1317, secured: false),
                TDMNode(name: "Terra testnet",  type: .terra,scheme: "http", host: "testwallet.syncnode.ro", rcpPort: 1347, secured: false),
                TDMNode(name: TDMNodeType.bitsong.rawValue,  type: .bitsong,scheme: "http", host: "lcd.testnet-2.bitsong.network", rcpPort: nil, secured: false),
                TDMNode(name: TDMNodeType.emoney.rawValue,  type: .emoney,scheme: "http", host: "testwallet.syncnode.ro", rcpPort: 1327, secured: false),
                TDMNode(name: "Iris Fuxy Testnet",  type: .iris_fuxi,scheme: "https", host: "lcd.testnet.irisnet.org", rcpPort: nil, secured: false)]
            
            PersistableGaiaNodes(nodes: nodes).savetoDisk()
        }
        
        noDataView.isHidden = nodes.count > 0
        editButton.isHidden = nodes.count == 0

        let _ = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main) { [weak self] note in
            self?.refreshNodes()
        }
        
        if let storedBook = GaiaAddressBook.loadFromDisk() as? GaiaAddressBook {
            addressBook = storedBook
        } else {
            addressBook.savetoDisk()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        toast?.hideToast()
        if shouldReloadData {
            tableView.reloadData()
            shouldReloadData = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        refreshNodes()
        navigationController?.navigationBar.barStyle = .default
        
        timer = Timer.scheduledTimer(withTimeInterval: GaiaConstants.refreshInterval * 3, repeats: true) { [weak self] timer in
            self?.refreshNodes()
        }
        
        if showHint {
            toast?.showToastAlert("You can use the nodes below or add your own trusted ndes.", type: .info, dismissable: true)
        }
        showHint = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        PersistableGaiaNodes(nodes: nodes).savetoDisk()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "NodeEditSegue" {
            let dest = segue.destination as? GaiaNodeController
            dest?.editMode = true
            dest?.curentNode = self.selectedNode
            dest?.editedNodeIndex = self.selectedIndex
            dest?.onCollectDataComplete = { [weak self] data in
                guard let weakSelf = self else { return }
                self?.nodes[weakSelf.selectedIndex] = data
                PersistableGaiaNodes(nodes: weakSelf.nodes).savetoDisk()
            }
            dest?.onDeleteComplete = { [weak self] index in
                guard let weakSelf = self else { return }
                self?.nodes.remove(at: index)
                self?.tableView.reloadData()
                PersistableGaiaNodes(nodes: weakSelf.nodes).savetoDisk()
            }
        }
        if segue.identifier == "CollectDataSegue" {
            let dest = segue.destination as? GaiaNodeController
            tableView.setEditing(false, animated: true)
            editButton.isSelected = false
            dest?.onCollectDataComplete = { [weak self] data in
                guard let weakSelf = self else { return }
                weakSelf.nodes.insert(data, at: 0)
                PersistableGaiaNodes(nodes: weakSelf.nodes).savetoDisk()
            }
        }
    }
    
    private func refreshNodes() {
        guard !tableView.isEditing else { return }
        weak var weakSelf = self
        if let validNodes = weakSelf?.nodes, validNodes.count > 0 {
            noDataView.isHidden = true
            editButton.isHidden = false

//            loadingView.startAnimating()
//            editButton.isEnabled = false
//            addButton.isEnabled = false
//            editButton.alpha = 0.2
            getStatusFor(nodes: validNodes) {
//                weakSelf?.editButton.alpha = 1.0
//                weakSelf?.editButton.isEnabled = true
//                weakSelf?.addButton.isEnabled = true
//                weakSelf?.loadingView.stopAnimating()
                weakSelf?.tableView.reloadData()
            }
        } else {
            editButton.isHidden = true
            noDataView.isHidden = false
        }
    }
    
    private func getStatusFor(nodes: [TDMNode], completion: (() -> ())?) {
        
        guard nodes.count > 0 else {
            DispatchQueue.main.async {
                completion?()
            }
            return
        }
        
        if let node = nodes.first {
            node.getStatus {
                node.getNodeInfo {  [weak self] in
                    var vnodes = nodes
                    vnodes.remove(at: 0)
                    self?.tableView.reloadData()
                    self?.getStatusFor(nodes: vnodes, completion: completion)
                }
            }
        }
    }
}

extension GaiaNodesController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nodes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "GaiaNodeCellID", for: indexPath) as! GaiaNodeCell
        let node = nodes[indexPath.item]
        cell.configure(with: node)
        return cell
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return editButton.isSelected ? .delete : .none
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return editButton.isSelected
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            nodes.remove(at: indexPath.item)
            noDataView.isHidden   = nodes.count > 0
            editButton.isSelected = nodes.count > 0
            editButton.isHidden = nodes.count == 0
        }
        tableView.reloadData()
        PersistableGaiaNodes(nodes: nodes).savetoDisk()
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let node = nodes[sourceIndexPath.item]
        nodes.remove(at: sourceIndexPath.item)
        nodes.insert(node, at: destinationIndexPath.item)
        PersistableGaiaNodes(nodes: nodes).savetoDisk()
    }
    
}

extension GaiaNodesController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedNode = self.nodes[indexPath.item]
        self.selectedIndex = indexPath.item
        DispatchQueue.main.async {
            if tableView.isEditing {
                self.shouldReloadData = true
                self.performSegue(withIdentifier: "NodeEditSegue", sender: self)
            } else {
                if (self.selectedNode?.state == .active || self.selectedNode?.state == .pending) {
                    AppContext.shared.node = self.selectedNode
                    self.performSegue(withIdentifier: "ShowNodeKeysSegue", sender: self)
                } else {
                    self.toast?.showToastAlert("The node is not active. Check the host and the ports", autoHideAfter: GaiaConstants.autoHideToastTime, type: .info, dismissable: true)
                }
            }
        }
    }
}
