//
//  GaiaTransactiionsController.swift
//  Cosmos Client
//
//  Created by Calin Chitu on 14/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi

class GaiaSettingsController: UIViewController, ToastAlertViewPresentable {

    var defaultFeeSigAmount: String { return AppContext.shared.node?.defaultTxFee  ?? "0" }
    var memo: String { return AppContext.shared.node?.defaultMemo  ?? "Syncnode's iOS Wallet 🙀" }

    var toast: ToastAlertView?
    
    @IBOutlet weak var loadingView: CustomLoadingView!
    @IBOutlet weak var toastHolderUnderView: UIView!
    @IBOutlet weak var toastHolderTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var topNavBarView: UIView!
    
    @IBOutlet weak var feeSectionTitleLabel: UILabel!
    @IBOutlet weak var feeTextField: UITextField!
    @IBOutlet weak var memoTextField: UITextField!
    @IBOutlet weak var feeApplyButton: UIButton!
    
    
    @IBAction func applyMemo(_ sender: Any) {
        let memo = memoTextField.text ?? ""
        let nodeName = AppContext.shared.node?.network ?? ""
        view.endEditing(true)
        toast?.showToastAlert("Memo set for node \(nodeName): \(memo)", autoHideAfter: GaiaConstants.autoHideToastTime, type: .info, dismissable: true)
        AppContext.shared.node?.defaultMemo = memo
        peristNodes()
    }
    
    @IBAction func applyFee(_ sender: Any) {
        let nodeName = AppContext.shared.node?.network ?? ""
        view.endEditing(true)
        if feeTextField.text == "" { feeTextField.text = "0" }
        if var value = feeTextField.text, let intVal = Int(value) {
            if intVal > 1000000 {
                value = "\(1000000)"
                feeTextField.text = value
                
                let alert = UIAlertController(title: nil, message: "One million should be enough, don't waste them on fees.", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "OK", style: .default)
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            }
            toast?.showToastAlert("Fee set for node \(nodeName): \(intVal)", autoHideAfter: GaiaConstants.autoHideToastTime, type: .info, dismissable: true)
            AppContext.shared.node?.defaultTxFee = "\(intVal)"
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
    
    @IBAction func openIpsxUrl(_ sender: Any) {
        guard let url = URL(string: "https://ip.sx") else { return }
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
                    savedNode.defaultTxFee = validNode.defaultTxFee
                    savedNode.defaultMemo  = validNode.defaultMemo
                }
            }
            PersistableGaiaNodes(nodes: savedNodes.nodes).savetoDisk()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toast = createToastAlert(creatorView: view, holderUnderView: toastHolderUnderView, holderTopDistanceConstraint: toastHolderTopConstraint, coveringView: topNavBarView)
        updateFeeLabel()
        
        let _ = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main) { [weak self] note in
            AppContext.shared.node?.getStatus {
                if AppContext.shared.node?.state == .unknown {
                    self?.performSegue(withIdentifier: "UnwindToNodes", sender: self)
                }
            }
        }
    }
    
    func updateFeeLabel() {
        var feeText = "Current settings: 0"
        if let amount = AppContext.shared.node?.defaultTxFee {
            let denom = AppContext.shared.account?.feeDenom ?? ""
            feeText = "Current settings: \(amount) \(denom)"
            if Double(amount) ?? 0 > 0.0 {
                feeTextField.text = amount
            }
        }
        feeSectionTitleLabel.text = feeText
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        memoTextField.text = memo
        
        if AppContext.shared.node?.type == TDMNodeType.iris || AppContext.shared.node?.type == TDMNodeType.iris_fuxi {
            feeTextField.isEnabled = false
            feeTextField.text = "0.41"
            feeSectionTitleLabel.text = "Current settings: 0.41 iris"
            feeApplyButton.isHidden = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
