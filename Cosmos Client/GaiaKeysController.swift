//
//  GaiaKeysController.swift
//  CosmosSample
//
//  Created by Calin Chitu on 11/01/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi

class GaiaKeysController: UIViewController, GaiaKeysManagementCapable {
    
    @IBOutlet weak var tableView: UITableView?
    
    var node: GaiaNode = GaiaNode(scheme: "https", host: "localhost", port: 1317)
    var dataSource: [GaiaKeyDisplayable] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        retrieveAllKeys { gaiaKeys, errorMessage in
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
