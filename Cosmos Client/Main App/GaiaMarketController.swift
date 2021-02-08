//
//  GaiaMarketController.swift
//  Syncnode
//
//  Created by Calin Chitu on 04/11/2020.
//  Copyright © 2020 Calin Chitu. All rights reserved.
//

import UIKit
import CosmosRestApi

class GaiaMarketController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var dataSource: [EmoneyInstruments] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        AppContext.shared.node?.getMarkets() { [weak self] markets in
            self?.dataSource = markets ?? []
            self?.tableView.reloadData()
        }
    }
}

extension GaiaMarketController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MarketCellID", for: indexPath)
        let item = dataSource[indexPath.item]
        let source = item.source ?? "-"
        let dest = item.destination ?? "-"
        let amount = item.lastPrice ?? "-"
        cell.textLabel?.text = "Last Price: " + amount
        cell.detailTextLabel?.text = "Pair: " + source + " / " + dest
        return cell
    }
    
    
}
