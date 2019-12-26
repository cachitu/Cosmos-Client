//
//  AppContext.swift
//  Syncnode
//
//  Created by Calin Chitu on 26/12/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation
import CosmosRestApi

class PersistableHashes: PersistCodable {
    
    let hashes: [String]
    
    init(hashes: [String]) {
        self.hashes = hashes
    }
}

struct AppContext {
    
    static var shared = AppContext()
    
    var node: TDMNode?
    var key: GaiaKey?
    var keysDelegate: LocalClient?
    var account: GaiaAccount?
    var redelgateFrom: String?
    
    private var pendingHashes: [String : String] = [:]
    
    private var peristHashesUID: String {
        let nodeID = node?.nodeID ?? ""
        let keyAddr = key?.address ?? ""
        return "PersistableHashes-\(nodeID)=\(keyAddr)"
    }
    
    var hashes: [String] {
        if let data = PersistableHashes.loadFromDisk(withUID: peristHashesUID) as? PersistableHashes {
            return data.hashes
        }
        return []
    }
    
    mutating func addHash(_ hash: String) {
        var data = hashes
        data.insert(hash, at: 0)
        pendingHashes[peristHashesUID] = hash
        PersistableHashes(hashes: data).savetoDisk(withUID: peristHashesUID)
        print("\(hash) saved")
    }
    
    func lastSubmitedHash() -> String? {
        return pendingHashes[peristHashesUID]
    }
    
    mutating func removeLastSubmitedHash() {
        pendingHashes[peristHashesUID] = nil
    }

    private init() {
    }
}
