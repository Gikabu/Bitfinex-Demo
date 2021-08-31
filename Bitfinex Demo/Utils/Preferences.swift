//
//  Preferences.swift
//  Bitfinex Demo
//
//  Created by Jonathan Gikabu on 28/08/2021.
//

import Foundation
import Network

class Preferences {
    let userDefaults = UserDefaults()
    
    private var initialized: Bool {
        return !ownUserId.isEmpty
    }
    
    var ownUserId: String {
        return userDefaults.string(forKey: "Bitfinex_Demo_ID") ?? ""
    }
    
    var userName: String {
        return userDefaults.string(forKey: "Bitfinex_Demo_Name") ?? ""
    }
    
    func initUser() {
        if !initialized {
            userDefaults.set(UUID().uuidString, forKey: "Bitfinex_Demo_ID")
        }
    }
    
    func setUserName(name: String) {
        userDefaults.set(name, forKey: "Bitfinex_Demo_Name")
        initUser()
    }
    
    var balanceUSD: Double {
        userDefaults.double(forKey: "Bitfinex_Demo_Balance_USD")
    }
    
    var balanceBTC: Double {
        userDefaults.double(forKey: "Bitfinex_Demo_Balance_BTC")
    }
    
    func modifyBalanceBTC(value: Double) {
        let newBal = balanceBTC + value
        userDefaults.set(newBal, forKey: "Bitfinex_Demo_Balance_BTC")
    }
    
    func modifyBalanceUSD(value: Double) {
        let newBal = balanceBTC + value
        userDefaults.set(newBal, forKey: "Bitfinex_Demo_Balance_USD")
    }
}
