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
    
    func test() {
        //cosmos14kxxegskp8lfuhpwj27hrv9uj8ufjvhzu5ucv5
        //cosmospub1addwnpepqvcu4mlcjpacdk28xh9e3ex0t5yrw877ylp82gpg8j7y32qf3zdjys07yww
        //cosmosvaloper14kxxegskp8lfuhpwj27hrv9uj8ufjvhzeqgdq8
        //cosmosvaloperpub1addwnpepqvcu4mlcjpacdk28xh9e3ex0t5yrw877ylp82gpg8j7y32qf3zdjyevmfpa
        //century possible car impact mutual grace place bomb drip expand search cube border elite ensure draft immune warrior route steak cram confirm kit sudden
        
        let mnemonic = "century possible car impact mutual grace place bomb drip expand search cube border elite ensure draft immune warrior route steak cram confirm kit sudden"
        //let mnemonic = Mnemonic.create()
        
        let seed = Mnemonic.createSeed(mnemonic: mnemonic)
        let coin: HDCoin = .cosmos
        let wallet = Wallet(seed: seed, coin: coin)
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
        let coin: HDCoin = .cosmos
        let wallet = Wallet(seed: seed, coin: coin)
        let account = wallet.generateAccount()
        
        var key = Key()
        key.name = name
        key.type = "Local managed \(password)"
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
}
