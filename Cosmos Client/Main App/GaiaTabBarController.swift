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

    private var shouldShowSecurity = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if AppContext.shared.node?.type == .emoney {
            self.viewControllers?.remove(at: 2)
        } else {
            self.viewControllers?.remove(at: 3)
        }
        
        shouldShowSecurity = AppContext.shared.node?.securedNodeAccess == true
        
        let _ = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main) { [weak self] note in
            
            guard !AppContext.shared.collectScreenOpen else { return }
            if AppContext.shared.node?.securedNodeAccess == true {
                if (self?.isViewLoaded == true && self?.view.window != nil) {
                    self?.onCollectAmountConfirm = nil
                    self?.performSegue(withIdentifier: "ShowSecuritySegue", sender: self)
                } else {
                    self?.shouldShowSecurity = true
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if shouldShowSecurity {
            onCollectAmountConfirm = nil
            promptForPin(mode: .unlock)
        }
        shouldShowSecurity = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? GaiaSecurityController {
            dest.collectMode = sender as? CollectMode ?? .unlock
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
    
    func promptForPin(mode: CollectMode) {
        performSegue(withIdentifier: "ShowSecuritySegue", sender: mode)
    }
    
    func promptForAmount() {
        performSegue(withIdentifier: "ShowCollectAmountSegue", sender: self)
    }
}
