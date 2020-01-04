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
    private var shouldShouwSecurity = false
    private var shouldPopNav = false
    override func viewDidLoad() {
        super.viewDidLoad()

        shouldShouwSecurity = AppContext.shared.node?.secured == true && AppContext.shared.node?.getPinFromKeychain() == nil
        
        let _ = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main) { [weak self] note in
            
            if AppContext.shared.node?.secured == true {
                self?.shouldPopNav = true
                if (self?.isViewLoaded == true && self?.view.window != nil){
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
            promptForPin()
        }
        shouldShouwSecurity = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? GaiaSecurityController {
            dest.onValidate = { [weak self] success in
                self?.onSecurityCheck?(success)
                if !success, self?.shouldPopNav == true {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
            dest.onCollect = { _ in
            }
        }
    }
    
    func promptForPin() {
        shouldPopNav = false
        performSegue(withIdentifier: "ShowSecuritySegue", sender: self)
    }
}
