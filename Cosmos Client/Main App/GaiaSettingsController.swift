//
//  GaiaTransactiionsController.swift
//  Cosmos Client
//
//  Created by Calin Chitu on 14/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi
import LocalAuthentication

class GaiaSettingsController: UIViewController, ToastAlertViewPresentable {

    var defaultFeeSigAmount: String { return AppContext.shared.node?.feeAmount  ?? "0" }
    var memo: String { return AppContext.shared.node?.defaultMemo  ?? "" }

    var toast: ToastAlertView?
    var context = LAContext()
    
    @IBOutlet weak var loadingView: CustomLoadingView!
    @IBOutlet weak var toastHolderUnderView: UIView!
    @IBOutlet weak var toastHolderTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var topNavBarView: UIView!
    
    @IBOutlet weak var feeSectionTitleLabel: UILabel!
    @IBOutlet weak var feeTextField: UITextField!
    @IBOutlet weak var memoTextField: UITextField!
    @IBOutlet weak var feeApplyButton: UIButton!
    
    @IBOutlet weak var useBioAuthLabel: UILabel!
    @IBOutlet weak var useBioAuthSwitch: UISwitch!
    @IBAction func bioAuthSwithcAction(_ sender: UISwitch) {
        if sender.isOn {
            context = LAContext()
            context.localizedCancelTitle = "Cancel"
            
            var error: NSError?
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                
                let reason = "Log in to your account"
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason ) { [weak self] success, error in
                    DispatchQueue.main.async { [weak self] in
                        if success {
                            
                            UserDefaults.standard.set(true, forKey: GaiaConstants.bioAuthDefautsKey)
                            self?.toast?.showToastAlert("Bio Auth is now enabled for this device. All PIN screens will attempth to use the biometric sensor first.", type: .info, dismissable: true)
                            
                        } else {
                            sender.isOn = false
                            UserDefaults.standard.set(false, forKey: GaiaConstants.bioAuthDefautsKey)
                            self?.toast?.showToastAlert(error?.localizedDescription ?? "Failed to authenticate", autoHideAfter: GaiaConstants.autoHideToastTime, type: .info, dismissable: true)
                        }
                        UserDefaults.standard.synchronize()
                    }
                }
            } else {
                sender.isOn = false
                UserDefaults.standard.set(false, forKey: GaiaConstants.bioAuthDefautsKey)
                UserDefaults.standard.synchronize()
                toast?.showToastAlert(error?.localizedDescription ?? "Can't evaluate policy", autoHideAfter: GaiaConstants.autoHideToastTime, type: .info, dismissable: true)
            }
        } else {
            UserDefaults.standard.set(false, forKey: GaiaConstants.bioAuthDefautsKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    @IBOutlet weak var nodeSecurityStateLabel: UILabel?
    @IBAction func nodeSecurityAction(_ sender: UIButton) {
        toast?.showToastAlert("Edit your node (from the Nodes screen) to enable or disable the pin for \(AppContext.shared.node?.name ?? "this node.")", type: .info, dismissable: true)
    }
    
    @IBAction func applyMemo(_ sender: Any) {
        let memo = memoTextField.text ?? ""
        let nodeName = AppContext.shared.node?.network ?? ""
        view.endEditing(true)
        toast?.showToastAlert("Memo set for node \(nodeName): \(memo)", autoHideAfter: GaiaConstants.autoHideToastTime, type: .info, dismissable: true)
        AppContext.shared.node?.defaultMemo = memo
        peristNodes()
    }
    
    @IBAction func applyFee(_ sender: Any) {
        guard let node = AppContext.shared.node else { return }
        let nodeName = node.network
        view.endEditing(true)
        if feeTextField.text == "" { feeTextField.text = "0" }
        if var value = feeTextField.text, let intVal = Int(value) {
            if intVal > Int(GaiaConstants.maxFee * pow(10, node.decimals)) {
                value = "\(Int(GaiaConstants.maxFee * pow(10, node.decimals)))"
                feeTextField.text = value
                
                let alert = UIAlertController(title: nil, message: "One million should be enough, don't waste them on fees.", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "OK", style: .default)
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            }
            toast?.showToastAlert("\(value) fee set for node \(nodeName).", autoHideAfter: GaiaConstants.autoHideToastTime, type: .info, dismissable: true)
            AppContext.shared.node?.feeAmount = "\(value)"
            updateFeeLabel()
            peristNodes()
        }
    }
    
    @IBAction func openKytzuUrl(_ sender: Any) {
        guard let url = URL(string: "https://www.linkedin.com/in/calinchitu/") else { return }
        UIApplication.shared.open(url)
    }
    
    @IBAction func openSyncnodeUrl(_ sender: Any) {
        guard let url = URL(string: "https://www.linkedin.com/in/gbunea/asse") else { return }
        UIApplication.shared.open(url)
    }
    
    @IBAction func openBitSentinel(_ sender: Any) {
        guard let url = URL(string: "https://bit-sentinel.com/") else { return }
        UIApplication.shared.open(url)
    }
    
    private func peristNodes() {
        if let savedNodes = PersistableGaiaNodes.loadFromDisk() as? PersistableGaiaNodes, let validNode = AppContext.shared.node {
            for savedNode in savedNodes.nodes {
                if savedNode.network == validNode.network {
                    savedNode.feeAmount = validNode.feeAmount
                    savedNode.defaultMemo  = validNode.defaultMemo
                }
            }
            PersistableGaiaNodes(nodes: savedNodes.nodes).savetoDisk()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        useBioAuthSwitch.isOn = UserDefaults.standard.bool(forKey: GaiaConstants.bioAuthDefautsKey)
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            useBioAuthSwitch.isEnabled = true
        } else {
            useBioAuthSwitch.isOn = false
            useBioAuthSwitch.isEnabled = false
        }
        toast = createToastAlert(creatorView: view, holderUnderView: toastHolderUnderView, holderTopDistanceConstraint: toastHolderTopConstraint, coveringView: topNavBarView)
        
        let _ = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main) { [weak self] note in
            AppContext.shared.node?.getStatus {
                if AppContext.shared.node?.state == .unknown {
                    self?.performSegue(withIdentifier: "UnwindToNodes", sender: self)
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateFeeLabel()
        memoTextField.text = memo
        nodeSecurityStateLabel?.text = AppContext.shared.node?.securedNodeAccess == true ? "Pin" : "Disabled"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func updateFeeLabel() {
        var feeText = "Current settings: 0"
        if let amount = AppContext.shared.node?.feeAmount {
            let denom = AppContext.shared.node?.feeDenom ?? ""
            feeText = "Current settings: " + amount + " " + denom
            if Double(amount) ?? 0 > 0.0 {
                feeTextField.text = amount
            }
        }
        feeSectionTitleLabel.text = feeText
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
    
    @IBAction func unwindToTarnsactions(segue:UIStoryboardSegue) {
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

extension GaiaSettingsController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
