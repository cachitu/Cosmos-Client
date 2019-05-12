//
//  GaiaKeysController.swift
//  CosmosSample
//
//  Created by Calin Chitu on 11/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi

class PersistableGaiaKeys: PersistCodable {
    
    let keys: [GaiaKey]
    
    init(keys: [GaiaKey]) {
        self.keys = keys
    }
}

class GaiaKeysController: UIViewController, GaiaKeysManagementCapable, ToastAlertViewPresentable, GaiaValidatorsCapable {
    
    var toast: ToastAlertView?
    let keysDelegate = LocalClient()
    
    @IBOutlet weak var loadingView: CustomLoadingView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noDataView: UIView!
    @IBOutlet weak var toastHolderUnderView: UIView!
    @IBOutlet weak var toastHolderTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var topNavBarView: UIView!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBAction func addAction(_ sender: Any) {
        self.performSegue(withIdentifier: "CreateKeySegue", sender: nil)
    }

    @IBAction func backAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func swipeAction(_ sender: Any) {
    }
    
    var node: GaiaNode? = GaiaNode()
    var dataSource: [GaiaKey] = []
    var selectedKey: GaiaKey?
    var selectedIndex: Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        keysDelegate.test()
        
        if let savedKeys = PersistableGaiaKeys.loadFromDisk() as? PersistableGaiaKeys {
            dataSource = savedKeys.keys
        } else {
            let mnemonic = "find cliff book sweet clip dwarf minor boat lamp visual maid reject crazy during hollow vanish sunny salt march kangaroo episode crash anger virtual"
            let appleKey = keysDelegate.recoverKey(from: mnemonic, name: "appleTest1", password: "test1234")
            let gaiaKey = GaiaKey(data: appleKey, nodeId: node?.nodeID ?? "")
            dataSource = [gaiaKey]
            PersistableGaiaKeys(keys: dataSource).savetoDisk()
        }

        toast = createToastAlert(creatorView: view, holderUnderView: toastHolderUnderView, holderTopDistanceConstraint: toastHolderTopConstraint, coveringView: topNavBarView)
        noDataView.isHidden = true
        
        let _ = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main) { [weak self] note in
            self?.node?.getStatus {
                if self?.node?.state == .unknown {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let validNode = node else { return }
        retrieveAllKeys(node: validNode, clientDelegate: keysDelegate) { [weak self] gaiaKeys, errorMessage in
            guard let keys = gaiaKeys else {
                //self?.toast?.showToastAlert(errorMessage ?? "Unknown error")
                self?.dataSource = []
                self?.tableView?.reloadData()
                self?.node?.getStakingInfo() { denom in }
                return
            }
            
            self?.dataSource = keys
            self?.noDataView.isHidden = keys.count > 0
            
            self?.tableView?.reloadData()
            self?.node?.getStakingInfo() { denom in }
        }
        
        loadingView.startAnimating()
        retrieveAllValidators(node: validNode) { [weak self] validators, errMsg in
            self?.loadingView.stopAnimating()
            if let validValidators = validators {
                for validator in validValidators {
                    validNode.knownValidators[validator.validator] = validator.moniker
                }
                if let savedNodes = PersistableGaiaNodes.loadFromDisk() as? PersistableGaiaNodes {
                    for savedNode in savedNodes.nodes {
                        if savedNode.network == validNode.network {
                            savedNode.knownValidators = validNode.knownValidators
                        }
                    }
                    PersistableGaiaNodes(nodes: savedNodes.nodes).savetoDisk()
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowKeyDetailsSegue" {
            let dest = segue.destination as? GaiaKeyController
            dest?.node = node
            dest?.keysDelegate = keysDelegate
            dest?.key = selectedKey
            dest?.selectedkeyIndex = selectedIndex
            dest?.onDeleteComplete = { [weak self] index in
                self?.dataSource.remove(at: index)
                self?.tableView.reloadData()
            }
        }
        if segue.identifier == "CreateKeySegue" {
            let dest = segue.destination as? GaiaKeyCreateController
            dest?.node = node
            dest?.keysDelegate = keysDelegate
        }
        if segue.identifier == "WalletSegueID" {
            let dest = segue.destination as? GaiaWalletController
            dest?.node = node
            dest?.keysDelegate = keysDelegate
            dest?.key = selectedKey
        }
        if segue.identifier == "ShowAddressBookSegue" {
            let nav = segue.destination as? UINavigationController
            let dest = nav?.viewControllers.first as? AddressesListController
            dest?.shouldPop = true
            dest?.onSelectAddress = { [weak self] selected in
                self?.tableView.reloadData()
            }
        }
    }
}


extension GaiaKeysController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GaiaKeyCellID", for: indexPath) as! GaiaKeyCell
        let key = dataSource[indexPath.section]
        cell.onCopy = { [weak self] in
            self?.toast?.showToastAlert("Address copied to clipboard", autoHideAfter: 3, type: .info, dismissable: true)
        }
        cell.configure(key: key)
        return cell
    }
    
}

extension GaiaKeysController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GaiaKeyHeaderCellID") as? GaiaKeyHeaderCell
        let key = dataSource[section]
        cell?.updateCell(sectionIndex: section, key: key)

        cell?.onForgetPassTap = { [weak self] section in
            self?.showPasswordAlert(title: nil, message: "The password for \(key.name) has been removed from the keychain", placeholder: "Minimum 8 charactes") { pass in
                if key.getPassFromKeychain() != pass {
                    self?.toast?.showToastAlert("Incorrect password, try again..", autoHideAfter: 5, type: .error, dismissable: true)
                }  else if key.forgetPassFromKeychain() == true {
                    self?.toast?.showToastAlert("The password for \(key.name) has been removed from the keychain", autoHideAfter: 5, type: .info, dismissable: true)
                } else {
                    self?.toast?.showToastAlert("Opps, didn't manage to remove it or didn't find it.", autoHideAfter: 5, type: .error, dismissable: true)
                }
                self?.tableView.reloadData()
            }
        }

        cell?.onMoreOptionsTap = { [weak self] section in
            self?.selectedKey = key
            self?.selectedIndex = section
            self?.performSegue(withIdentifier: "ShowKeyDetailsSegue", sender: self)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let key = dataSource[indexPath.section]
        selectedKey = key
        
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "WalletSegueID", sender: self)
        }
    }
}

extension Array where Element : Equatable {
    
    public mutating func mergeElements<C : Collection>(newElements: C) where C.Iterator.Element == Element{
        let filteredList = newElements.filter({!self.contains($0)})
        self.append(contentsOf: filteredList)
    }
    
}
