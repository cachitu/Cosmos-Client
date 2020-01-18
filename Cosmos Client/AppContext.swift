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
    
    let hashes: [PersitsableHash]
    
    init(hashes: [PersitsableHash]) {
        self.hashes = hashes
    }
}

struct AppContext {
    
    static var shared = AppContext()
    
    var collectedAmount: String = "0"
    var collectedDenom: String = ""
    var collectOnlyFee = false
    var colletForStaking = false
    var colletAsset: Coin? = nil
    var colletMaxAmount: String? = nil
    var collectSummary: [String] = []
    
    var collectScreenOpen = false
    var node: TDMNode?
    var key: GaiaKey?
    var keysDelegate: LocalClient?
    var account: GaiaAccount?
    var redelgateFrom: String?
    
    var onHashPolingPending: (() -> ())?
    var onHashPolingDone: (() -> ())?

    var nodeDecimals: Int {
        return Int(node?.decimals ?? 6)
    }
    
    var isIrisType: Bool {
        return node?.type == .iris || node?.type == .iris_fuxi
    }
    
    private var pendingHashes: [String : PersitsableHash] = [:]
    private var polingTimer: Timer?
    
    private var peristHashesUID: String {
        let nodeID = node?.nodeID ?? ""
        let keyAddr = key?.address ?? ""
        return "PersistableHashes-\(nodeID)=\(keyAddr)"
    }
    
    var hashes: [PersitsableHash] {
        if let data = PersistableHashes.loadFromDisk(withUID: peristHashesUID) as? PersistableHashes {
            return data.hashes
        }
        return []
    }
    
    mutating func addHash(_ hash: PersitsableHash) {
        var data = hashes
        data.insert(hash, at: 0)
        pendingHashes[peristHashesUID] = hash
        PersistableHashes(hashes: data).savetoDisk(withUID: peristHashesUID)
    }
    
    mutating func clearHashes() {
        PersistableHashes(hashes: []).savetoDisk(withUID: peristHashesUID)
    }

    func lastSubmitedHash() -> PersitsableHash? {
        return pendingHashes[peristHashesUID]
    }
    
    mutating func removeLastSubmitedHash() {
        pendingHashes[peristHashesUID] = nil
    }

    private init() {
    }
    
    func stopHashPoling() {
        AppContext.shared.polingTimer?.invalidate()
        AppContext.shared.onHashPolingPending = nil
        AppContext.shared.onHashPolingDone = nil
    }
    
    func startHashPoling(hash: PersitsableHash) {
        
        guard let validNode = node, let validKey = key else { return }
        AppContext.shared.polingTimer?.invalidate()
        guard hash == lastSubmitedHash() else { return }
        
        AppContext.shared.polingTimer?.invalidate()
        key?.getHash(node: validNode, gaiaKey: validKey, hash: hash.hash) { resp, errMsg in
            AppContext.shared.polingTimer?.invalidate()
            if errMsg == nil {
                DispatchQueue.main.async {
                    AppContext.shared.onHashPolingDone?()
                }
                AppContext.shared.removeLastSubmitedHash()
            } else {
                DispatchQueue.main.async {
                    AppContext.shared.onHashPolingPending?()
                }
                AppContext.shared.polingTimer = Timer.scheduledTimer(withTimeInterval: GaiaConstants.refreshInterval / 2, repeats: false) { timer in
                    AppContext.shared.startHashPoling(hash: hash)
                }
            }
        }
    }    
}
