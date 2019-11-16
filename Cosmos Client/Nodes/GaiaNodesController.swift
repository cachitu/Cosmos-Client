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
    
    var addressBook: GaiaAddressBook = GaiaAddressBook(items: [])
    
    fileprivate var nodes: [TDMNode] =  []
    fileprivate weak var selectedNode: TDMNode?
    fileprivate var selectedIndex: Int = 0
    
    private weak var timer: Timer?
    private var showHint = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toast = createToastAlert(creatorView: view, holderUnderView: toastHolderUnderView, holderTopDistanceConstraint: toastHolderTopConstraint, coveringView: topNavBarView)
        
        if let savedNodes = PersistableGaiaNodes.loadFromDisk() as? PersistableGaiaNodes {
            nodes = savedNodes.nodes
            showHint = false
        } else {
            nodes = [
                TDMNode(name: "Cosmos", type: .cosmos, scheme: "http", host: "node01.ip.sx", rcpPort: 1317),
                TDMNode(name: "Iris",  type: .iris,scheme: "http", host: "node01.ip.sx", rcpPort: 1327),
                TDMNode(name: "Terra",  type: .terra,scheme: "http", host: "node01.ip.sx", rcpPort: 1337),
                TDMNode(name: "Kava",  type: .kava,scheme: "http", host: "node01.ip.sx", rcpPort: 1347)]
            PersistableGaiaNodes(nodes: nodes).savetoDisk()
        }
        
        noDataView.isHidden = nodes.count > 0
        
        let _ = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main) { [weak self] note in
            self?.refreshNodes()
        }
        
        if let storedBook = GaiaAddressBook.loadFromDisk() as? GaiaAddressBook {
            addressBook = storedBook
        } else {
            addressBook.savetoDisk()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        refreshNodes()
        navigationController?.navigationBar.barStyle = .default
        
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] timer in
            self?.refreshNodes()
        }
        
        if showHint {
            //toast?.showToastAlert("Use IPSX nodes for test purposes only, add your own trusted node for real use.", type: .info, dismissable: true)
        }
        showHint = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        toast?.hideToast()
        PersistableGaiaNodes(nodes: nodes).savetoDisk()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "NodeEditSegue" {
            let dest = segue.destination as? GaiaNodeController
            dest?.editMode = true
            dest?.collectedData = self.selectedNode
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
            dest?.onCollectDataComplete = { [weak self] data in
                guard let weakSelf = self else { return }
                weakSelf.nodes.insert(data, at: 0)
                PersistableGaiaNodes(nodes: weakSelf.nodes).savetoDisk()
            }
        }
        if segue.identifier == "ShowNodeKeysSegue", let selected = selectedNode {
            let dest = segue.destination as? GaiaKeysController
            dest?.node = selected
        }
    }
    
    private func refreshNodes() {
        weak var weakSelf = self
        if let validNodes = weakSelf?.nodes, validNodes.count > 0 {
            noDataView.isHidden = true
            loadingView.startAnimating()
            for node in validNodes {
                node.getStatus {
                    node.getNodeInfo {
                        weakSelf?.loadingView.stopAnimating()
                        weakSelf?.tableView.reloadData()
                    }
                }
            }
        } else {
            noDataView.isHidden = false
        }
    }
}

extension GaiaNodesController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return nodes.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "GaiaNodeCellID", for: indexPath) as! GaiaNodeCell
        let node = nodes[indexPath.section]
        cell.configure(with: node)
        return cell
    }
    
}

extension GaiaNodesController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GaiaNodeHeaderCellID") as? GaiaNodeHeaderCell
        let node = nodes[section]
        cell?.updateCell(sectionIndex: section, name: node.name)
        cell?.onTap = { [weak self] section in
            self?.selectedNode = self?.nodes[section]
            self?.selectedIndex = section
            self?.performSegue(withIdentifier: "NodeEditSegue", sender: self)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedNode = nodes[indexPath.section]
        if (selectedNode?.state == .active || selectedNode?.state == .pending) {
            self.performSegue(withIdentifier: "ShowNodeKeysSegue", sender: self)
        } else {
            self.toast?.showToastAlert("The node is not active. Check the host and the ports", autoHideAfter: 15, type: .info, dismissable: true)
        }
    }
}
