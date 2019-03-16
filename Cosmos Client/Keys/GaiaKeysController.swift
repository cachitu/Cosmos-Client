//
//  GaiaKeysController.swift
//  CosmosSample
//
//  Created by Calin Chitu on 11/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi

class GaiaKeysController: UIViewController, GaiaKeysManagementCapable, ToastAlertViewPresentable {
    
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
    
    @IBAction func addAction(_ sender: Any) {
        if GaiaLocalClient.signingImplemented {
            self.performSegue(withIdentifier: "CreateKeySegue", sender: nil)
        } else {
            self.performSegue(withIdentifier: "ShowAddressBookSegue", sender: nil)
        }
    }

    @IBAction func backAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func swipeAction(_ sender: Any) {
        debugMode = true
    }
    
    var node: GaiaNode? = GaiaNode()
    var dataSource: [GaiaKey] = []
    var selectedKey: GaiaKey?
    var selectedIndex: Int?

    private var debugMode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        loadingView.startAnimating()
        retrieveAllKeys(node: validNode) { [weak self] gaiaKeys, errorMessage in
            self?.loadingView.stopAnimating()
            guard let keys = gaiaKeys else {
                //self?.toast?.showToastAlert(errorMessage ?? "Unknown error")
                let hk = GaiaKey(seed: nil, nodeId: self?.node?.nodeID ?? "test")
                self?.dataSource = [hk]
                self?.tableView?.reloadData()
                self?.node?.getStakingInfo() { denom in }
                return
            }
            let debug = self?.debugMode ?? false
            
            self?.dataSource = debug ? keys : keys.filter { $0.isUnlocked || $0.name == "appleTest1" }
            self?.noDataView.isHidden = keys.count > 0
            
            self?.tableView?.reloadData()
            self?.debugMode = false
            self?.node?.getStakingInfo() { denom in }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowKeyDetailsSegue" {
            let dest = segue.destination as? GaiaKeyController
            dest?.node = self.node
            dest?.key = selectedKey
            dest?.selectedkeyIndex = self.selectedIndex
            dest?.onDeleteComplete = { [weak self] index in
                self?.dataSource.remove(at: index)
                self?.tableView.reloadData()
            }
        }
        if segue.identifier == "CreateKeySegue" {
            let dest = segue.destination as? GaiaKeyCreateController
            dest?.node = self.node
        }
        if segue.identifier == "WalletSegueID" {
            let dest = segue.destination as? GaiaWalletController
            dest?.node = self.node
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
        
        guard key.isUnlocked == false else {
            performSegue(withIdentifier: "WalletSegueID", sender: self)
            return
        }
        
        DispatchQueue.main.async {
            
            guard let validNode = self.node else { return }

            let alertMessage = "Enter the password for \(key.name) to acces the wallet. It will be stored encripted in the device's keychain if the unlock is succesfull."
            self.showPasswordAlert(title: nil, message: alertMessage, placeholder: "Minimum 8 characters") { [weak self] pass in
                self?.loadingView.startAnimating()
                key.unlockKey(node: validNode, password: pass) { [weak self] success, message in
                    self?.loadingView.stopAnimating()
                    if success == true {
                        key.savePassToKeychain(pass: pass)
                        self?.toast?.showToastAlert("The key has been unlocked. You can now acces your wallet.", autoHideAfter: 5, type: .info, dismissable: true)
                        self?.tableView.reloadData()
                    } else if let msg = message {
                        self?.toast?.showToastAlert(msg, autoHideAfter: 5, type: .error, dismissable: true)
                    } else {
                        self?.toast?.showToastAlert("Opps, I failed.", autoHideAfter: 5, type: .error, dismissable: true)
                    }
                }
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
