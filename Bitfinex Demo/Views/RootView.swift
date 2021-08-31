//
//  RootView.swift
//  Bitfinex Demo
//
//  Created by Jonathan Gikabu on 28/08/2021.
//

import SwiftUI

struct RootView: View {
    @StateObject var manager: ExchangeManager = ExchangeManager()
    @AppStorage("Bitfinex_Demo_Name") var username: String = ""
    
    var body: some View {
        NavigationView {
            if !username.isEmptyOrWhitespace {
                DashboardView()
                    .environmentObject(manager)
            } else {
                ProfileSetupView()
            }
        }.onAppear(perform: {
            Preferences().initUser()
            if sharedBrowser == nil {
                sharedBrowser = PeerBrowser(delegate: manager)
            }
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
