//
//  WalletsListController.swift
//
//  Created by Calin Chitu on 12/11/2018.
//  Copyright © 2018 Cristina Virlan. All rights reserved.
//

import UIKit
import CosmosRestApi

class AddressesListController: UIViewController, ToastAlertViewPresentable {

    @IBOutlet weak var loadingView: CustomLoadingView!
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var topConstraintOutlet: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableTopSeparator: UIView!
    @IBOutlet weak var noWalletHelpLabel: UILabel!
    
    var toast: ToastAlertView?
    var longPressGesture: UILongPressGestureRecognizer?
    var singlePressGesture: UITapGestureRecognizer?
    var shouldPop = false

    var onSelectAddress: ((_ addressItem: GaiaAddressBookItem?) -> ())?
    var gaiaAddresses: [GaiaAddressBookItem] = []
    private var selectedAddress: GaiaAddressBookItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        toast = createToastAlert(creatorView: self.view, holderUnderView: separatorView, holderTopDistanceConstraint: topConstraintOutlet, coveringView: topBarView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        selectedAddress = nil
        if let gaiaAddress = GaiaAddressBook.loadFromDisk() as? GaiaAddressBook {
            gaiaAddresses = gaiaAddress.items
            tableView.reloadData()
        }
    }
    
    private func configureUI() {
        tableView.tableFooterView = UIView()
    }

    @IBAction func closeButton(_ sender: Any) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func addWalletAction(_ sender: Any) {
        DispatchQueue.main.async { self.performSegue(withIdentifier: "AddWalletSegueID", sender: self) }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
    
    private func showDeleteConfirmationAlert(index: IndexPath) {
        let ethAddress = gaiaAddresses[index.item]
        let alertMessage = ethAddress.address
        let alertController = UIAlertController(title: "Delete Address Confirmation Alert Title", message: alertMessage, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action:UIAlertAction) in
        }
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] (action:UIAlertAction) in
            self?.gaiaAddresses.remove(at: index.item)
            let _ = GaiaAddressBook(items: self?.gaiaAddresses ?? []).savetoDisk()
            self?.tableView.reloadData()
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        self.present(alertController, animated: true, completion: nil)
    }
}

extension AddressesListController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            showDeleteConfirmationAlert(index: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return gaiaAddresses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "GaiaAddressCellID", for: indexPath) as! GaiaWalletCell
        let address = gaiaAddresses[indexPath.item]
        cell.configure(address: address, hideDisclosure: shouldPop)
        return cell
    }
}

extension AddressesListController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedAddress = gaiaAddresses[indexPath.item]
        if shouldPop {
            DispatchQueue.main.async {
                self.onSelectAddress?(self.selectedAddress)
                self.navigationController?.dismiss(animated: true)
            }
        } else {
            DispatchQueue.main.async { self.performSegue(withIdentifier: "ViewWalletSegueID", sender: self) }
        }
    }
    
}

class GaiaWalletCell: UITableViewCell {
    
    @IBOutlet weak var aliasLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var disclosureImage: UIImageView!
    @IBOutlet weak var disclousureTrailing: NSLayoutConstraint!
    
    func configure(address: GaiaAddressBookItem, hideDisclosure: Bool = false) {
        aliasLabel.text = address.name
        addressLabel.text = address.address
        
        disclosureImage.isHidden = hideDisclosure
        disclousureTrailing.constant = hideDisclosure ? 0 : 15
        layoutIfNeeded()
    }
}
