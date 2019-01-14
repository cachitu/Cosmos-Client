//
//  GaiaKeyController.swift
//  Cosmos Client
//
//  Created by Calin Chitu on 14/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit

class GaiaKeyController: UIViewController, ToastAlertViewPresentable {
    
    @IBOutlet weak var titleLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet weak var topSeparatorView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var deleteNode: RoundedButton!
    
    @IBOutlet weak var topConstraintOutlet: NSLayoutConstraint!
    
    var toast: ToastAlertView?
    
    private var fieldsStateDic: [String : Bool] = ["field1" : false, "field2" : false, "field3" : true, "field4" : true]
    
    var onDeleteComplete: ((_ index: Int)->())?
    var selectedkeyIndex: Int?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        toast = createToastAlert(creatorView: view, holderUnderView: topSeparatorView, holderTopDistanceConstraint: topConstraintOutlet, coveringView: topBarView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    @IBAction func collectAndClose(_ sender: Any) {
        self.view.endEditing(true)
        self.dismiss(animated: true)
    }
    
    @IBAction func deleteNode(_ sender: Any) {
        self.view.endEditing(true)
        if let index = selectedkeyIndex {
            onDeleteComplete?(index)
        }
        self.dismiss(animated: true)
    }
    
    @IBAction func closeButtonAction(_ sender: Any) {
        
        self.view.endEditing(true)
        self.dismiss(animated: true)
    }
    
    private func prePopulate() {
        
    }
    
    private func updateUI() {
        
    }
}
