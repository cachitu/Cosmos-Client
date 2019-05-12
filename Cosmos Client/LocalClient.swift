//
//  LocalClient.swift
//  Cosmos Client
//
//  Created by kytzu on 23/03/2019.
//  Copyright © 2019 Calin Chitu. All rights reserved.
//

import Foundation
import CosmosRestApi

public class LocalClient: KeysClientDelegate {
    
    var coinType: HDCoin = .cosmos
    
    func test() {
        //cosmos14kxxegskp8lfuhpwj27hrv9uj8ufjvhzu5ucv5
        //cosmospub1addwnpepqvcu4mlcjpacdk28xh9e3ex0t5yrw877ylp82gpg8j7y32qf3zdjys07yww
        //cosmosvaloper14kxxegskp8lfuhpwj27hrv9uj8ufjvhzeqgdq8
        //cosmosvaloperpub1addwnpepqvcu4mlcjpacdk28xh9e3ex0t5yrw877ylp82gpg8j7y32qf3zdjyevmfpa
        //century possible car impact mutual grace place bomb drip expand search cube border elite ensure draft immune warrior route steak cram confirm kit sudden
        
        let mnemonic = "century possible car impact mutual grace place bomb drip expand search cube border elite ensure draft immune warrior route steak cram confirm kit sudden"
        //let mnemonic = Mnemonic.create()
        
        let seed = Mnemonic.createSeed(mnemonic: mnemonic)
        let wallet = Wallet(seed: seed, coin: coinType)
        let account = wallet.generateAccount()
        print("cosmos14kxxegskp8lfuhpwj27hrv9uj8ufjvhzu5ucv5")
        print(account.address)
        print("cosmospub1addwnpepqvcu4mlcjpacdk28xh9e3ex0t5yrw877ylp82gpg8j7y32qf3zdjys07yww")
        print(account.publicAddress)
        print("cosmosvaloper14kxxegskp8lfuhpwj27hrv9uj8ufjvhzeqgdq8")
        print(account.validator)
        print("cosmosvaloperpub1addwnpepqvcu4mlcjpacdk28xh9e3ex0t5yrw877ylp82gpg8j7y32qf3zdjyevmfpa")
        print(account.publicValidator)
    }
    
    public func getSavedKeys() -> [GaiaKey] {
        
        if let savedKeys = PersistableGaiaKeys.loadFromDisk() as? PersistableGaiaKeys {
            return savedKeys.keys
        } else {
            return []
        }
    }
    
    public func generateMnemonic() -> String {
        return Mnemonic.create()
    }
    
    public func recoverKey(from mnemonic: String, name: String, password: String) -> Key {
        
        let seed = Mnemonic.createSeed(mnemonic: mnemonic)
        let wallet = Wallet(seed: seed, coin: coinType)
        let account = wallet.generateAccount()
        
        var key = Key()
        key.name = name
        key.type = "Local managed"
        key.password = password
        key.mnemonic = mnemonic
        key.address = account.address
        key.pubAddress = account.publicAddress
        key.validator = account.validator
        key.pubValidator = account.publicValidator
        
        return key
    }
    
    public func createKey(with name: String, password: String) -> Key {
        let mnemonic = Mnemonic.create()
        return recoverKey(from: mnemonic, name: name, password: password)
    }
    
    public func deleteKey(with name: String, password: String) -> NSError? {
        if let savedKeys = PersistableGaiaKeys.loadFromDisk() as? PersistableGaiaKeys {
            var keys = savedKeys.keys
            var index = 0
            for gaiaKey in keys {
                if gaiaKey.name == name, gaiaKey.password == password {
                    keys.remove(at: index)
                }
                index += 1
            }
            PersistableGaiaKeys(keys: keys).savetoDisk()
        }
        return nil
    }
    
    public func sign(transferData: TransactionTx?, account: GaiaAccount, node: GaiaNode, completion:((RestResult<[TransactionTx]>) -> Void)?) {
        
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
        let seed = Mnemonic.createSeed(mnemonic: account.gaiaKey.mnemonic)
        let wallet = Wallet(seed: seed, coin: coinType)
        let hdaccount = wallet.generateAccount()

        let type = "tendermint/PubKeySecp256k1"
        let value = hdaccount.privateKey.publicKey.getBase64()
        var hash = ""

        do {
            try hash = hdaccount.privateKey.sign(hash: goodBuffer).base64EncodedString()
        } catch {
            print("failed")
        }
        hash = String(hash.dropLast().dropLast())
        hash += "=="
        
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
        
        //let signer = Signer()
        //signer.unsafeSign(transferData: transferData, completion: completion)
    }
}

public struct TypePrefix {
    static let MsgSend = "2A2C87FA"
    static let NewOrderMsg = "CE6DC043"
    static let CancelOrderMsg = "166E681B"
    static let StdTx = "F0625DEE"
    static let PubKeySecp256k1 = "EB5AE987"
    static let SignatureSecp256k1 = "7FC4A495"
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

//The only purpose of this unsafe signer is to compare with local signing
public class Signer: RestNetworking {
    
    let connectData: ConnectData
    
    public init(scheme: String = "http", host: String = "localhost", port: Int = 1318) {
        connectData = ConnectData(scheme: scheme, host: host, port: port)
    }
    
    
    public func unsafeSign(transferData: TransactionTx?, completion:((RestResult<[TransactionTx]>) -> Void)?) {
        //The pass and key is stored on the remote nodjs service (see the nodejs code below:
        genericRequest(bodyData: transferData, connData: connectData, path: "/sign", reqMethod: "POST", singleItemResponse: true, timeout: 10, completion: completion)
    }
    
    func jsCodeSample() {
        /*
        
         
        #sign.sh -->
        password="..."
        echo "${password}" | gaiacli tx sign unsigned.json --from=... --chain-id=... > signed.json
        echo "Done signing"
        #sign.sh <--
         
         
        #index.js -->
        var express = require('express');
        var express = require("express");
        var bodyParser = require("body-parser");
        var fs = require('fs');
        
        var app = express();
        app.use(bodyParser.urlencoded({ extended: true }));
        app.use(bodyParser.json());
        
        app.post('/sign', function (req, res) {
            
            var json = JSON.stringify(req.body);
            fs.unlink('unsigned.json', function (err) {
                fs.unlink('signed.json', function (err) {
                    fs.writeFile("unsigned.json", json, function (err) {
                        if (err) throw err;
                        const
                        { spawn } = require('child_process'),
                        sign = spawn('./sign.sh');
                        
                        sign.stdout.on('data', data => {
                        fs.readFile('signed.json', function (err, content) {
                        if (err) throw err;
                        console.log('------ Sending signed resonse ------');
                        var parseJson = JSON.parse(content);
                        console.log(JSON.stringify(parseJson));
                        res.send(parseJson);
                        console.log('------ Done ------');
                        console.log(' ');
                        })
                        });
                        
                        sign.stderr.on('data', data => {
                        console.log(`stderr: ${data}`);
                        res.send(data);
                        });
                        
                        sign.on('close', code => {
                        });
                    });
                });
            });
            
            console.log('------ Received unsigned resonse ------');
            console.log(json);
        })
        
        var server = app.listen(1318, function () {
            var host = server.address().address
            var port = server.address().port
            
            console.log("Listening at http://%s:%s", host, port)
        })
        #index.js <--
        */
    }
}
