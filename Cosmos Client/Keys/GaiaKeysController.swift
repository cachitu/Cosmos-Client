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
    
    @IBOutlet weak var loadingView: CustomLoadingView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var noDataView: UIView!
    @IBOutlet weak var toastHolderUnderView: UIView!
    @IBOutlet weak var toastHolderTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var topNavBarView: UIView!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    
    @IBAction func editButtonAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        tableView.setEditing(sender.isSelected, animated: true)
    }
    
    @IBAction func addAction(_ sender: Any) {
        showCreateOptions()
    }

    @IBAction func backAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func swipeAction(_ sender: Any) {
    }
    
    var dataSource: [GaiaKey] = []
    var filteredDataSource: [GaiaKey] {
        return dataSource.filter { $0.type == AppContext.shared.node?.type.rawValue }
    }
    var selectedKey: GaiaKey?
    var selectedIndex: Int?

    private func createTheDefauktKey() {
        
        guard AppContext.shared.node?.appleKeyCreated == false else {
            return
        }
        
        let mnemonic = "find cliff book sweet clip dwarf minor boat lamp visual maid reject crazy during hollow vanish sunny salt march kangaroo episode crash anger virtual"
        
        if let appleKey = AppContext.shared.keysDelegate?.recoverKey(from: mnemonic, name: "appleTest1", password: "test1234") {
            let gaiaKey = GaiaKey(data: appleKey, nodeId: AppContext.shared.node?.nodeID ?? "")
            dataSource.append(gaiaKey)
            AppContext.shared.node?.appleKeyCreated = true
            if let savedNodes = PersistableGaiaNodes.loadFromDisk() as? PersistableGaiaNodes, let validNode = AppContext.shared.node {
                for savedNode in savedNodes.nodes {
                    if savedNode.network == validNode.network {
                        savedNode.appleKeyCreated = true
                    }
                }
                PersistableGaiaNodes(nodes: savedNodes.nodes).savetoDisk()
            }

            PersistableGaiaKeys(keys: dataSource).savetoDisk()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addButton.layer.cornerRadius = addButton.frame.size.height / 2
        AppContext.shared.keysDelegate = LocalClient(networkType: AppContext.shared.node?.type ?? .cosmos, netID: AppContext.shared.node?.nodeID ?? "-1")
        if let savedKeys = PersistableGaiaKeys.loadFromDisk() as? PersistableGaiaKeys {
            dataSource = savedKeys.keys
            if filteredDataSource.count == 0 {
                createTheDefauktKey()
            }
        } else {
            createTheDefauktKey()
        }
        
        toast = createToastAlert(creatorView: view, holderUnderView: toastHolderUnderView, holderTopDistanceConstraint: toastHolderTopConstraint, coveringView: topNavBarView)
        noDataView.isHidden = filteredDataSource.count > 0
        editButton.isHidden = !noDataView.isHidden
        
        let _ = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main) { [weak self] note in
            AppContext.shared.node?.getStatus {
                if AppContext.shared.node?.state == .unknown {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let validNode = AppContext.shared.node, let delegate = AppContext.shared.keysDelegate else { return }
        retrieveAllKeys(node: validNode, clientDelegate: delegate) { [weak self] gaiaKeys, errorMessage in
            guard let keys = gaiaKeys else {
                //self?.toast?.showToastAlert(errorMessage ?? "Unknown error")
                self?.dataSource = []
                self?.tableView?.reloadData()
                AppContext.shared.node?.getStakingInfo() { denom in }
                return
            }
            
            self?.dataSource = keys
            self?.noDataView.isHidden = self?.filteredDataSource.count ?? 0 > 0
            self?.editButton.isHidden = self?.filteredDataSource.count ?? 0 == 0

            self?.tableView?.reloadData()
            AppContext.shared.node?.getStakingInfo() { denom in }
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
    
    func showCreateOptions() {
        
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let create = UIAlertAction(title: "Create or Recover", style: .default) { [weak self] alertAction in
            self?.performSegue(withIdentifier: "CreateKeySegue", sender: nil)
        }
        
        let watch = UIAlertAction(title: "Watch Only", style: .default) { [weak self] alertAction in
            self?.performSegue(withIdentifier: "ShowAddressBookSegue", sender: nil)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        optionMenu.addAction(create)
        optionMenu.addAction(watch)
        optionMenu.addAction(cancelAction)
        
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    func createWatchKey(name: String, address: String) {
        
        let matches = dataSource.filter() { $0.name == name && $0.address == address && $0.watchMode == true }
        if let _ = matches.first {
            toast?.showToastAlert("This key is already added to your watch list.", autoHideAfter: 5, type: .error, dismissable: true)
            return
        }
        
        let gaiaKey = GaiaKey(
            name: name,
            address: address,
            valAddress: nil,
            nodeType: AppContext.shared.node?.type ?? .cosmos, nodeId: AppContext.shared.node?.nodeID ?? "")
        
        DispatchQueue.main.async {
            self.dataSource.insert(gaiaKey, at: 0)
            self.tableView.reloadData()
            PersistableGaiaKeys(keys: self.dataSource).savetoDisk()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        tableView.setEditing(false, animated: true)
        editButton.isSelected = false
        if segue.identifier == "ShowKeyDetailsSegue" {
            let dest = segue.destination as? GaiaKeyController
            dest?.selectedkeyIndex = selectedIndex
        }
        if segue.identifier == "ShowAddressBookSegue" {
            let nav = segue.destination as? UINavigationController
            let dest = nav?.viewControllers.first as? AddressesListController
            dest?.shouldPop = true
            dest?.addressPrefix = AppContext.shared.node?.adddressPrefix ?? ""
            
            dest?.onSelectAddress = { [weak self] selected in
                if let validAddress = selected {
                    self?.createWatchKey(name: validAddress.name, address: validAddress.address)
                }
            }
        }
    }
    
    func handleDeleteKey(_ key: GaiaKey, completion: ((_ success: Bool) -> ())?) {
        
        if key.watchMode == true {
            completion?(true)
            return
        }
        
        var alertMessage = "Enter the password for \(key.name) to delete the wallet. The passowrd and seed will be permanentely removed from the keychain."
        if key.name == "appleTest1" {
            alertMessage = "This is the Apple Test key, needed for the iOS Appstore review. To delete this address, the password is test1234."
        }
        self.showPasswordAlert(title: nil, message: alertMessage, placeholder: "Minimum 8 characters") { [weak self] pass in
            if key.password == pass {
                completion?(true)
            } else {
                self?.toast?.showToastAlert("Wrong unlock key password.", autoHideAfter: 3, type: .error, dismissable: true)
                completion?(false)
            }
        }
    }
    
    private func purgeKey(_ key: GaiaKey, index: Array<GaiaKey>.Index) {
        
        let _ = key.forgetPassFromKeychain()
        let _ = key.forgetMnemonicFromKeychain()
        self.dataSource.remove(at: index)
        PersistableGaiaKeys(keys: self.dataSource).savetoDisk()
        tableView.reloadData()
        toast?.showToastAlert("\(key.name) successfully deleted", autoHideAfter: 3, type: .info, dismissable: true)

        if self.filteredDataSource.count == 0 {
            self.tableView.setEditing(false, animated: true)
            self.editButton.isSelected = false
            self.noDataView.isHidden = false
            self.editButton.isHidden = !self.noDataView.isHidden
        }
    }
    
}


extension GaiaKeysController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredDataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GaiaKeyCellID", for: indexPath) as! GaiaKeyCell
        let key = filteredDataSource[indexPath.item]
        cell.onCopy = { [weak self] in
            self?.toast?.showToastAlert("Address copied to clipboard", autoHideAfter: 3, type: .info, dismissable: true)
        }
        cell.configure(key: key, image: AppContext.shared.node?.nodeLogo)
        return cell
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let key = filteredDataSource[indexPath.item]
            if let index = dataSource.firstIndex(where: { $0 == key } ) {
                handleDeleteKey(key) { success in
                    if success {
                        self.purgeKey(key, index: index)
                    } else {
                        let alert = UIAlertController(title: "Do you want to delete this key anyway? This action can't be undone and the mnemonic is lost forever.", message: "", preferredStyle: UIAlertController.Style.alert)
                        
                        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { alertAction in
                        }
                        
                        let action = UIAlertAction(title: "Confirm", style: .destructive) { [weak self] alertAction in
                            self?.toast?.hideToast()
                            self?.purgeKey(key, index: index)
                        }
                        
                        alert.addAction(cancelAction)
                        alert.addAction(action)
                        
                        self.present(alert, animated:true, completion: nil)
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let skey = filteredDataSource[sourceIndexPath.item]
        let dkey = filteredDataSource[destinationIndexPath.item]
        if let sindex = dataSource.firstIndex(where: { $0 == skey } ),
            let dindex = dataSource.firstIndex(where: { $0 == dkey } ) {
            dataSource.remove(at: sindex)
            dataSource.insert(skey, at: dindex)
            PersistableGaiaKeys(keys: dataSource).savetoDisk()
            tableView.reloadData()
        }
    }
}

extension GaiaKeysController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let key = filteredDataSource[indexPath.item]
        selectedKey = key
        AppContext.shared.key = key
        
        DispatchQueue.main.async {
            if tableView.isEditing {
                self.selectedIndex = indexPath.item
                self.performSegue(withIdentifier: "ShowKeyDetailsSegue", sender: self)
            } else {
                self.performSegue(withIdentifier: "WalletSegueID", sender: self)
            }
        }
    }
}

extension Array where Element : Equatable {
    
    public mutating func mergeElements<C : Collection>(newElements: C) where C.Iterator.Element == Element{
        let filteredList = newElements.filter({!self.contains($0)})
        self.append(contentsOf: filteredList)
    }
    
}
