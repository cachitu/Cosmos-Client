//
//  AddWalletController.swift
//  IPSX
//
//  Created by Calin Chitu on 23/04/2018.
//  Copyright © 2018 Cristina Virlan. All rights reserved.
//

import UIKit
import AVFoundation
import CosmosRestApi

class AddressController: UIViewController, ToastAlertViewPresentable {

    @IBOutlet weak var screenTitleLabel: UILabel?
    @IBOutlet weak var sectionTitleLabel: UILabel?
    @IBOutlet weak var pasteAddrButton: UIButton!
    @IBOutlet weak var copyAddrButton: UIButton?
    @IBOutlet weak var qrcodeButton: UIButton!
    @IBOutlet weak var loadingView: CustomLoadingView!
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var walletNameRichTextField: RichTextFieldView!
    @IBOutlet weak var ethAddresRichTextField: RichTextFieldView!
    @IBOutlet weak var saveButton: UIButton?
    @IBOutlet weak var topConstraintOutlet: NSLayoutConstraint!
    
    var toast: ToastAlertView?
    var gaiaAddress: GaiaAddressBookItem?
    var continueBottomDist: CGFloat = 0.0
    var shouldPop = false
    
    var onAddressEdited: ((_ alias: String)->())?

    private var fieldsStateDic: [String : Bool] = ["walletName" : true, "gaiaAddress" : false]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        observreFieldsState()
        if let address = gaiaAddress {
            fieldsStateDic = ["walletName" : true, "gaiaAddress" : true]
            walletNameRichTextField.contentTextField?.text = address.name
            ethAddresRichTextField.contentTextField?.text  = address.address
            screenTitleLabel?.text = "Edit ETH Address text"
            sectionTitleLabel?.text = "Edit your ETH address text"
            ethAddresRichTextField.contentTextField?.isEnabled = false
            qrcodeButton.isHidden = true
            pasteAddrButton.isHidden = true
        } else {
            screenTitleLabel?.text = "Add ETH Address text"
            sectionTitleLabel?.text = "Add your ETH address text"
        }
        copyAddrButton?.isHidden = !pasteAddrButton.isHidden
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }
    
    @objc func appWillEnterForeground() {
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
        walletNameRichTextField.nextResponderField = ethAddresRichTextField.contentTextField
        walletNameRichTextField.validationRegex    = RichTextFieldView.validName
        walletNameRichTextField.limitLenght        = 30
    }
    
    private func observreFieldsState() {
        walletNameRichTextField.onFieldStateChange = { [weak self] state in
            guard let weakSelf = self else { return }
            let curentNameText = weakSelf.walletNameRichTextField.contentTextField?.text ?? ""
            weakSelf.fieldsStateDic["walletName"] = state
            weakSelf.saveButton?.isEnabled = !weakSelf.fieldsStateDic.values.contains(false) && curentNameText != weakSelf.gaiaAddress?.name && curentNameText.count > 0
        }
        ethAddresRichTextField.onFieldStateChange = { [weak self] state in
            guard let weakSelf = self else { return }
            let curentNameText = weakSelf.walletNameRichTextField.contentTextField?.text ?? ""
            weakSelf.fieldsStateDic["gaiaAddress"] = state
            weakSelf.saveButton?.isEnabled = !weakSelf.fieldsStateDic.values.contains(false) && weakSelf.ethAddresRichTextField.contentTextField?.text != weakSelf.gaiaAddress?.address && curentNameText.count > 0
        }
    }
    
    @IBAction func backAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func saveAction(_ sender: UIButton) {
        
        let alias = walletNameRichTextField.contentTextField?.text ?? ""
        let address = ethAddresRichTextField.contentTextField?.text ?? ""
        
        if let storedBook = GaiaAddressBook.loadFromDisk() as? GaiaAddressBook {
            var addrItems: [GaiaAddressBookItem] = []
            let item = GaiaAddressBookItem(name: alias, address: address)
            addrItems.insert(item, at: 0)
            storedBook.items.mergeElements(newElements: addrItems)
            storedBook.savetoDisk()
        }
        
        self.navigationController?.popViewController(animated: true)
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
            ethAddresRichTextField.contentTextField?.text = clipboardText
            ethAddresRichTextField.refreshStatus()
        }
    }
    
    @IBAction func copyAction(_ sender: Any) {
        if let address = ethAddresRichTextField.contentTextField?.text {
            UIPasteboard.general.string = address
            toast?.showToastAlert("Address Copied", autoHideAfter: 5, type: .info, dismissable: true)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    private func presentQRScanner() {
        DispatchQueue.main.async {
            let scannerController = QRScannViewController()
            scannerController.onCodeFound = { [weak self] code in
                self?.ethAddresRichTextField.contentTextField?.text = code
                self?.ethAddresRichTextField.refreshStatus()
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
    
}


class QRScannViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var onCodeFound: ((_ newCode: String)->())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
     }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    private func setup() {
        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    private func failed() {
        let ac = UIAlertController(title: "No Camera Title Alert", message: "No Camera Message Alert", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }
        
        dismiss(animated: true)
    }
    
    private func found(code: String) {
        onCodeFound?(code)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        dismiss(animated: true)
    }
}
