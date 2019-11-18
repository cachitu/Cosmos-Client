//
//  LocalClient.swift
//  Cosmos Client
//
//  Created by kytzu on 23/03/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation
import CosmosRestApi
import TendermintSigner
import CryptoKit
import CommonCrypto

public class LocalClient: KeysClientDelegate {
    
    let signer: TendermintClient
    let type: TDMNodeType
    
    init(networkType: TDMNodeType) {
        self.type = networkType
        switch networkType {
        case .cosmos, .cosmosTestnet:
            self.signer = TendermintClient(coin: .cosmos)
        case .iris  : self.signer = TendermintClient(coin: .iris)
        case .terra : self.signer = TendermintClient(coin: .terra)
        case .kava  : self.signer = TendermintClient(coin: .kava)
        }
    }
    
    public func getSavedKeys() -> [GaiaKey] {
        
        if let savedKeys = PersistableGaiaKeys.loadFromDisk() as? PersistableGaiaKeys {
            return savedKeys.keys
        } else {
            return []
        }
    }
    
    public func generateMnemonic() -> String {
        signer.generateMnemonic()
    }
    
    public func recoverKey(from mnemonic: String, name: String, password: String) -> TDMKey {
        let account = signer.recoverKey(from: mnemonic)
        
        var key = TDMKey()
        key.name = name
        key.type = type
        key.password = password
        key.mnemonic = mnemonic
        key.address = account.address
        key.pubAddress = account.publicAddress
        key.validator = account.validator
        key.pubValidator = account.publicValidator
        
        return key
    }

    public func deleteKey(with address: String, password: String) -> NSError? {
        if let savedKeys = PersistableGaiaKeys.loadFromDisk() as? PersistableGaiaKeys {
            var keys = savedKeys.keys
            var index = 0
            for gaiaKey in keys {
                if gaiaKey.address == address, gaiaKey.password == password {
                    keys.remove(at: index)
                }
                index += 1
            }
            PersistableGaiaKeys(keys: keys).savetoDisk()
        }
        return nil
    }
    
    public func sign(transferData: TransactionTx?, account: GaiaAccount, node: TDMNode, completion:((RestResult<[TransactionTx]>) -> Void)?) {
        
        var signable = TxSignable()
        signable.accountNumber = account.accNumber
        signable.chainId = node.network
        signable.fee = transferData?.value?.fee
        signable.memo = transferData?.value?.memo
        signable.msgs = transferData?.value?.msg
        signable.sequence = account.accSequence
        
        var jsonData = Data()
        var jsString = ""
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        encoder.dataEncodingStrategy = .base64
        do {
            jsonData = try encoder.encode(signable)
            jsString = String(data: jsonData, encoding: String.Encoding.macOSRoman) ?? ""
        } catch {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Could not encode data"])
            completion?(.failure(error))
        }
        jsString = jsString.replacingOccurrences(of: "\\", with: "")

        let goodBuffer = jsString.data(using: .ascii)?.sha256() ?? Data()
        let hdaccount = signer.recoverKey(from: account.gaiaKey.mnemonic)

        let type = "tendermint/PubKeySecp256k1"
        let value = hdaccount.privateKey.publicKey.getBase64()
        let hash = signer.signHash(transferData: goodBuffer, hdAccount: hdaccount)

        
        let sig = TxValueSignature(
            sig: hash,
            type: type,
            value: value,
            accNum: account.accNumber,
            seq: account.accSequence)
        var signed = transferData
        signed?.value?.signatures = [sig]

        if let final = signed {
            completion?(.success([final]))
        }
    }
}

public struct TxSignable: Codable {

    public var accountNumber: String?
    public var chainId: String?
    public var fee: TxValueFee?
    public var memo: String?
    public var msgs: [TxValueMsg]?
    public var sequence: String?

    public init() {

    }

    enum CodingKeys : String, CodingKey {
        case accountNumber = "account_number"
        case chainId = "chain_id"
        case fee
        case memo
        case msgs
        case sequence
    }
}
