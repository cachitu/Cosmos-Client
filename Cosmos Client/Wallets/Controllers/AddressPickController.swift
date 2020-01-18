//
//  AddressPickController.swift
//  Syncnode
//
//  Created by Calin Chitu on 18/01/2020.
//  Copyright © 2020 Calin Chitu. All rights reserved.
//

import UIKit
import AVFoundation
import CosmosRestApi

class AddressPickController: UIViewController, ToastAlertViewPresentable {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var screenTitleLabel: UILabel?
    @IBOutlet weak var pasteAddrButton: UIButton!
    @IBOutlet weak var qrcodeButton: UIButton!
    @IBOutlet weak var loadingView: CustomLoadingView!
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var walletNameRichTextField: RichTextFieldView!
    @IBOutlet weak var addresRichTextField: RichTextFieldView!
    
    @IBOutlet weak var useButton: UIButton!
    @IBOutlet weak var saveButton: UIButton?
    @IBOutlet weak var topConstraintOutlet: NSLayoutConstraint!
    
    var toast: ToastAlertView?
    var selectedAddress: GaiaAddressBookItem? {
        didSet {
            fieldsStateDic = ["walletName" : true, "gaiaAddress" : true]
            walletNameRichTextField.contentTextField?.text = selectedAddress?.name
            addresRichTextField.contentTextField?.text  = selectedAddress?.address
            addresRichTextField.refreshStatus()
        }
    }
    
    var onSelectAddress: ((_ addressItem: GaiaAddressBookItem?) -> ())?
    var gaiaAddresses: [GaiaAddressBookItem] = []

    var continueBottomDist: CGFloat = 0.0
    var addressPrefix: String = AppContext.shared.node?.adddressPrefix ?? ""

    var onAddressEdited: ((_ alias: String)->())?

    private var fieldsStateDic: [String : Bool] = ["walletName" : true, "gaiaAddress" : false]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        observreFieldsState()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }
    
    @objc func appWillEnterForeground() {
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let gaiaAddress = GaiaAddressBook.loadFromDisk() as? GaiaAddressBook {
            gaiaAddresses = gaiaAddress.items.filter { $0.address.contains(addressPrefix) }
            tableView.reloadData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupTextViews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        toast = createToastAlert(creatorView: self.view, holderUnderView: separatorView, holderTopDistanceConstraint: topConstraintOutlet, coveringView: topBarView)
    }
    
    private func setupTextViews() {
        walletNameRichTextField.nextResponderField = addresRichTextField.contentTextField
        walletNameRichTextField.validationRegex    = RichTextFieldView.validName
        walletNameRichTextField.limitLenght        = 30
        let prefix = AppContext.shared.node?.adddressPrefix ?? ""
        RichTextFieldView.prefix                   = prefix + "1"
        addresRichTextField.validationRegex        = RichTextFieldView.validTDMAddress
    }
    
    private func observreFieldsState() {
        walletNameRichTextField.onFieldStateChange = { [weak self] state in
            guard let weakSelf = self else { return }
            let curentNameText = weakSelf.walletNameRichTextField.contentTextField?.text ?? ""
            weakSelf.fieldsStateDic["walletName"] = state
            weakSelf.saveButton?.isEnabled = !weakSelf.fieldsStateDic.values.contains(false) && curentNameText != weakSelf.selectedAddress?.name && curentNameText.count > 0
        }
        addresRichTextField.onFieldStateChange = { [weak self] state in
            guard let weakSelf = self else { return }
            let curentNameText = weakSelf.walletNameRichTextField.contentTextField?.text ?? ""
            weakSelf.fieldsStateDic["gaiaAddress"] = state
            weakSelf.saveButton?.isEnabled = !weakSelf.fieldsStateDic.values.contains(false) && weakSelf.addresRichTextField.contentTextField?.text != weakSelf.selectedAddress?.address && curentNameText.count > 0
            weakSelf.useButton.isEnabled = state
        }
    }
    
    @IBAction func backAction(_ sender: Any) {
        dismiss(animated: true) {
            
        }
    }

    @IBAction func saveToAddressBookAction(_ sender: UIButton) {
        let alias = walletNameRichTextField.contentTextField?.text ?? ""
        let address = addresRichTextField.contentTextField?.text ?? ""
        
        if let storedBook = GaiaAddressBook.loadFromDisk() as? GaiaAddressBook {
            let item = GaiaAddressBookItem(name: alias, address: address)
            storedBook.items.insert(item, at: 0)
            storedBook.savetoDisk()
            gaiaAddresses = storedBook.items.filter { $0.address.contains(addressPrefix) }
            tableView.reloadData()
        }
    }
    
    @IBAction func useAction(_ sender: UIButton) {
        
        
        let alias = walletNameRichTextField.contentTextField?.text ?? ""
        let address = addresRichTextField.contentTextField?.text ?? ""
        let item = GaiaAddressBookItem(name: alias, address: address)
        self.dismiss(animated: true) {
            self.onSelectAddress?(item)
        }
    }
    
    @IBAction func qrCodeAction(_ sender: Any) {
        if AVCaptureDevice.authorizationStatus(for: .video) ==  .authorized {
            presentQRScanner()
        } else {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { [weak self] (granted: Bool) in
                DispatchQueue.main.async {
                    if granted {
                        self?.presentQRScanner()
                    } else {
                        self?.openSettingsAction()
                    }
                }
            })
        }
    }
    
    @IBAction func pasteAction(_ sender: Any) {
        if let clipboardText = UIPasteboard.general.string {
            addresRichTextField.contentTextField?.text = clipboardText
            addresRichTextField.refreshStatus()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    private func presentQRScanner() {
        DispatchQueue.main.async {
            let scannerController = QRScannViewController()
            scannerController.onCodeFound = { [weak self] code in
                self?.addresRichTextField.contentTextField?.text = code
                self?.addresRichTextField.refreshStatus()
            }
            self.present(scannerController, animated: true) {
            }
        }
    }
    
    func openSettingsAction() {
        
        self.toast?.hideToast()
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            toast?.showToastAlert("Settings Camera Redirect Message", type: .error)
            return
        }
        
        let alertController = UIAlertController(title: "No Camera Title Alert", message: "No Camera Message Alert", preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { [weak self] (action:UIAlertAction) in
            self?.toast?.showToastAlert("Settings Camera Redirect Message", type: .error)
        }
        
        let deleteAction = UIAlertAction(title: "Go to Settings", style: .default) { [weak self] (action:UIAlertAction) in
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            } else {
                self?.toast?.showToastAlert("Settings Camera Redirect Message", type: .error)
            }
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        self.present(alertController, animated: true, completion: nil)
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

extension AddressPickController: UITableViewDataSource {
    
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
        cell.configure(address: address)
        return cell
    }
}

extension AddressPickController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedAddress = gaiaAddresses[indexPath.item]
        DispatchQueue.main.async {
            self.useButton.isEnabled = true
        }
    }
    
}

extension String {

    func isAlphanumeric() -> Bool {
        return self.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) == nil && self != ""
    }
}
