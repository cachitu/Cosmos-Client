//
//  GaiaKeysController.swift
//  CosmosSample
//
//  Created by Calin Chitu on 11/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi

class GaiaKeysController: UIViewController, GaiaKeysManagementCapable, ToastAlertViewPresentable {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewTopConstraint: NSLayoutConstraint!
    
    var toast: ToastAlertView?
    var node: GaiaNode = GaiaNode(scheme: "https", host: "localhost", port: 1317)
    var dataSource: [GaiaKeyDisplayable] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toast = createToastAlert(creatorView: view, holderUnderView: tableView, holderTopDistanceConstraint: tableViewTopConstraint)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        toast?.showToastAlert("Fetch keys")
        print("Fetch keys")
        retrieveAllKeys { gaiaKeys, errorMessage in
            print("Fetch keys done")
            guard let keys = gaiaKeys else {
                print(errorMessage ?? "Unknown error")
                return
            }
            self.dataSource = keys
            self.tableView?.reloadData()
        }
    }
}


extension GaiaKeysController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "keyCell", for: indexPath)
        let key = dataSource[indexPath.item]
        cell.textLabel?.text = key.name
        cell.detailTextLabel?.text = key.address
        return cell
    }
}
