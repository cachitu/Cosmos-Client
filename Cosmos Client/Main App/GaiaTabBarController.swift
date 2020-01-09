//
//  GaiaTabBarController.swift
//  Syncnode
//
//  Created by Calin Chitu on 04/01/2020.
//  Copyright © 2020 Calin Chitu. All rights reserved.
//

import UIKit

class GaiaTabBarController: UITabBarController {

    var onSecurityCheck: ((_ success: Bool) -> ())?
    var onCollectAmountConfirm: (() -> ())?
    var onCollectAmountCancel: (() -> ())?

    private var shouldShouwSecurity = false

    override func viewDidLoad() {
        super.viewDidLoad()

        shouldShouwSecurity = AppContext.shared.node?.securedNodeAccess == true
        
        let _ = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main) { [weak self] note in
            
            if AppContext.shared.node?.securedNodeAccess == true {
                if (self?.isViewLoaded == true && self?.view.window != nil) {
                    self?.onCollectAmountConfirm = nil
                    self?.performSegue(withIdentifier: "ShowSecuritySegue", sender: self)
                } else {
                    self?.shouldShouwSecurity = true
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if shouldShouwSecurity {
            onCollectAmountConfirm = nil
            promptForPin()
        }
        shouldShouwSecurity = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? GaiaSecurityController {
            dest.onValidate = { [weak self] success in
                self?.onSecurityCheck?(success)
                if !success {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
            dest.onCollect = { _ in
            }
        }
        if let dest = segue.destination as? GaiaCollectAmountController {
            dest.onConfirm = { [weak self] in
                self?.onCollectAmountConfirm?()
            }
            dest.onCancel = { [weak self] in
                self?.onCollectAmountCancel?()
                AppContext.shared.colletMaxAmount = nil
                AppContext.shared.colletAsset = nil
            }
        }
    }
    
    func promptForPin() {
        performSegue(withIdentifier: "ShowSecuritySegue", sender: self)
    }
    
    func promptForAmount() {
        performSegue(withIdentifier: "ShowCollectAmountSegue", sender: self)
    }
}
