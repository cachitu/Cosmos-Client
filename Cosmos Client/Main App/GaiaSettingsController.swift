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

    var node: TDMNode?
    var key: GaiaKey?
    var account: GaiaAccount?
    var feeAmount: String { return node?.defaultTxFee  ?? "0" }
    var memo: String { return node?.defaultMemo  ?? "IPSX iOS Wallet" }

    var toast: ToastAlertView?
    
    @IBOutlet weak var loadingView: CustomLoadingView!
    @IBOutlet weak var toastHolderUnderView: UIView!
    @IBOutlet weak var toastHolderTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var topNavBarView: UIView!
    @IBOutlet weak var bottomTabbarView: CustomTabBar!
    @IBOutlet weak var bottomTabbarDownConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var feeSectionTitleLabel: UILabel!
    @IBOutlet weak var feeTextField: UITextField!
    @IBOutlet weak var memoTextField: UITextField!
    @IBOutlet weak var feeApplyButton: UIButton!
    
    
    var forwardCounter = 0
    var onUnwind: ((_ toIndex: Int) -> ())?

    @IBAction func applyMemo(_ sender: Any) {
        let memo = memoTextField.text ?? ""
        let nodeName = node?.network ?? ""
        view.endEditing(true)
        toast?.showToastAlert("Memo set for node \(nodeName): \(memo)", autoHideAfter: 5, type: .info, dismissable: true)
        node?.defaultMemo = memo
        peristNodes()
    }
    
    @IBAction func applyFee(_ sender: Any) {
        let nodeName = node?.network ?? ""
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
            toast?.showToastAlert("Fee set for node \(nodeName): \(intVal)", autoHideAfter: 5, type: .info, dismissable: true)
            node?.defaultTxFee = "\(intVal)"
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
        if let savedNodes = PersistableGaiaNodes.loadFromDisk() as? PersistableGaiaNodes, let validNode = node {
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
        bottomTabbarView.selectIndex(3)
        bottomTabbarView.onTap = { [weak self] index in
            switch index {
            case 0:
                self?.onUnwind?(0)
                self?.performSegue(withIdentifier: "UnwindToWallet", sender: nil)
            case 1:
                self?.onUnwind?(1)
                self?.performSegue(withIdentifier: "UnwindToValidators", sender: nil)
            case 2: self?.dismiss(animated: false)
            default: break
            }
        }
        updateFeeLabel()
        
        let _ = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main) { [weak self] note in
            self?.node?.getStatus {
                if self?.node?.state == .unknown {
                    self?.performSegue(withIdentifier: "UnwindToNodes", sender: self)
                }
            }
        }
    }
    
    func updateFeeLabel() {
        var feeText = "Current settings: 0"
        if let amount = node?.defaultTxFee {
            let denom = account?.feeDenom ?? ""
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
    
    @IBAction func unwindToTarnsactions(segue:UIStoryboardSegue) {
        bottomTabbarView.selectIndex(3)
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
