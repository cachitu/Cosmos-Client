//
//  UViewController+extensions.swift
//  Cosmos Client
//
//  Created by Calin Chitu on 15/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit

public extension UIViewController {

    public func showPasswordAlert(title: String?, message: String?, placeholder: String?, completion: @escaping ((_ password: String) -> ())) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        let action = UIAlertAction(title: "Submit", style: .default) { alertAction in
            let textField = alert.textFields![0] as UITextField
            completion(textField.text ?? "")
        }
        
        alert.addTextField { textField in
            textField.placeholder = placeholder
            textField.isSecureTextEntry = true
        }
        
        alert.addAction(cancelAction)
        alert.addAction(action)
        
        self.present(alert, animated:true, completion: nil)
    }

    fileprivate func showDestructiveAlert(title: String?, message: String?, completion: @escaping (() -> ())) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        let action = UIAlertAction(title: "Confirm", style: .destructive) { alertAction in
            completion()
        }
        alert.addAction(cancelAction)
        alert.addAction(action)
        
        self.present(alert, animated:true, completion: nil)
    }

}
