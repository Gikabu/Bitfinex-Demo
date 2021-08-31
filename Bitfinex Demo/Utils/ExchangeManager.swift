//
//  ExchangeUtils.swift
//  Bitfinex Demo
//
//  Created by Jonathan Gikabu on 28/08/2021.
//

import Foundation
import SwiftUI
import Network
import SwiftyJSON

class ExchangeManager: ObservableObject, PeerBrowserDelegate, PeerConnectionDelegate {
    @Published var balBTC: Double = 0
    @Published var balUSD: Double = 0
    @Published var availableBalBTC: Double = 0
    @Published var availableBalUSD: Double = 0
    @Published var browserError: String?
    @Published var advertiserError: String?
    @Published var results = [NWBrowser.Result]()
    @Published var connectionStatus: Int = -1
    @Published var myListing: Listing?
    @Published var thread: [Exchange] = [Exchange]()
    
    private let rate: Double = 49000
    private let prefs = Preferences()
    
    init() {
        refreshBalance()
        self.availableBalBTC = self.balBTC
        self.availableBalUSD = self.balUSD
    }
    
    func refreshBalance() {
        self.balBTC = prefs.balanceBTC
        self.balUSD = prefs.balanceUSD
    }
    
    func offerBuyBTC(value: Double) {
        self.availableBalUSD = availableBalUSD - (value * rate)
    }
    
    func offerSellBTC(value: Double) {
        self.availableBalBTC = availableBalBTC - value
    }
    
    func confirmBuyBTC(value: Double) {
        prefs.modifyBalanceBTC(value: value)
        prefs.modifyBalanceUSD(value: -(value * rate))
        refreshBalance()
    }
    
    func confirmSellBTC(value: Double) {
        prefs.modifyBalanceBTC(value: -value)
        prefs.modifyBalanceUSD(value: (value * rate))
        refreshBalance()
    }
    
    // When the discovered peers change, update the list.
    func refreshResults(results: Set<NWBrowser.Result>) {
        
        self.results.removeAll()
        for result in results {
            if case let NWEndpoint.service(name: name, type: _, domain: _, interface: _) = result.endpoint {
                print("!!!!!!!!!! \(results.count).... \(name)")
                if !name.contains(Preferences().userName) {
                    self.results.append(result)
                } else {
                    self.myListing = Listing(json: JSON(parseJSON: name))
                }
            }
        }
    }

    func displayBrowseError(_ error: NWError) {
        self.browserError = "Error \(error)"
        if error == NWError.dns(DNSServiceErrorType(kDNSServiceErr_NoAuth)) {
            self.browserError = "Not allowed to access the network"
        }
    }
    
    func connectionReady() {
        self.connectionStatus = 1
    }

    func displayAdvertiseError(_ error: NWError) {
        self.advertiserError = "Error \(error)"
        if error == NWError.dns(DNSServiceErrorType(kDNSServiceErr_NoAuth)) {
            self.advertiserError = "Not allowed to access the network"
        }
    }

    func connectionFailed() {
        self.connectionStatus = 0
        disconnect()
        
    }
    
    func receivedMessage(content: Data?, message: NWProtocolFramer.Message) {
        guard let content = content else {
            return
        }
        
        switch message.messageType {
        case .invalid:
            print("Received invalid message")
        case .exchange:
            handleMessage(content, message)
        }
    }
    
    func handleMessage(_ content: Data, _ message: NWProtocolFramer.Message) {
        if let jsonString = String(data: content, encoding: .unicode) {
            let exchange = Exchange(json: JSON(parseJSON: jsonString))
            thread.append(exchange)
        }
    }
    
    func disconnect() {
        if let connection = sharedConnection {
            connection.cancel()
        }
        sharedConnection = nil
    }
}
