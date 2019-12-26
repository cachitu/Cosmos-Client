//
//  AppContext.swift
//  Syncnode
//
//  Created by Calin Chitu on 26/12/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation
import CosmosRestApi

struct AppContext {
    
    static var shared = AppContext()
    
    var node: TDMNode?
    var key: GaiaKey?
    var keysDelegate: LocalClient?
    var account: GaiaAccount?
    var redelgateFrom: String?
    
    private init() {
    }
}
