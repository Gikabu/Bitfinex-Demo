//
//  DashboardView.swift
//  Bitfinex Demo
//
//  Created by Jonathan Gikabu on 29/08/2021.
//

import SwiftUI
import Network
import SwiftyJSON

struct DashboardView: View {
    @EnvironmentObject var manager: ExchangeManager
    @State private var price: String = ""
    @State private var amount: String = ""
    @State private var selectedListing: Listing?
    @State private var negotiating: Bool = false
    
    var postDisabled: Bool {
        return price.isEmptyOrWhitespace || amount.isEmptyOrWhitespace
    }
    
    
    var body: some View {
        VStack {
            List {
                Section(header: Text("Exchange Sell")) {
                    GroupBox {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Price USD")
                                TextField("Enter price", text: $price)
                                    .padding(8)
                                    .keyboardType(.numberPad)
                                    .background(RoundedRectangle(cornerRadius: 12).stroke().foregroundColor(.secondary))
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading) {
                                Text("Amount BTC")
                                TextField("Enter amount", text: $amount)
                                    .padding(8)
                                    .keyboardType(.numberPad)
                                    .background(RoundedRectangle(cornerRadius: 12).stroke().foregroundColor(.secondary))
                            }
                        }
                        
                        Divider()
                            .padding(.vertical, 10)
                        
                        HStack {
                            Button(action: { clearFields() }, label: {
                                VStack {
                                    Text("Clear".uppercased())
                                        .padding(8)
                                }
                                .padding(.horizontal)
                                .background(RoundedRectangle(cornerRadius: 20).stroke())
                            })
                            
                            Button(action: { postListing() }, label: {
                                VStack {
                                    Text("Post".uppercased())
                                        .padding(8)
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal)
                                .background(RoundedRectangle(cornerRadius: 20))
                            })
                            .disabled(postDisabled)
                        }
                    }
                }
                
                Section(header: Text("Exchange Buy")) {
                    ScrollView {
                        VStack {
                            if manager.results.isEmpty {
                                HStack {
                                    Spacer()
                                    Text("No listings yet...")
                                        .italic()
                                        .fontWeight(.thin)
                                    Spacer()
                                }
                                .padding()
                            } else {
                                ForEach(manager.results, id: \.self) { result in
                                    if case let NWEndpoint.service(name: name, type: _, domain: _, interface: _) = result.endpoint, let listing = Listing(json: JSON(parseJSON: name)) {
                                        Button(action: { makeOffer(result: result, listing: listing) }, label: {
                                            VStack {
                                                HStack(spacing: 10) {
                                                    Image("bitfinex-avatar")
                                                        .resizable()
                                                        .frame(width: 50, height: 50, alignment: .center)
                                                        .clipShape(Circle())
                                                    VStack(alignment: .leading) {
                                                        Text(listing.name)
                                                            .font(.body)
                                                            .fontWeight(.semibold)
                                                        HStack {
                                                            Text("Price USD: \(listing.price)")
                                                                .font(.callout)
                                                                .fontWeight(.light)
                                                            Text("|")
                                                            Text("Amount BTC: \(listing.amount)")
                                                                .font(.callout)
                                                                .fontWeight(.light)
                                                        }
                                                    }
                                                    Spacer()
                                                }
                                                .frame(maxWidth: .infinity)
                                            }
                                        })
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(GroupedListStyle())
            
        }
        .onReceive(manager.$connectionStatus, perform: { value in
            if !negotiating, value == 1, manager.myListing != nil {
                selectedListing = manager.myListing
                negotiating = true
            }
        })
        .onChange(of: negotiating, perform: { value in
            if !negotiating, let connection = sharedConnection {
                if connection.initiatedConnection {
                    connection.cancel()
                    sharedConnection = nil
                }
            }
        })
        .sheet(isPresented: $negotiating, content: {
            if let listing = selectedListing {
                NegotiationView(isPresented: $negotiating, listing: listing)
                    .environmentObject(manager)
            }
        })
        .navigationBarTitle("Trading", displayMode: .inline)
        .navigationBarItems(leading:
                                HStack {
                                    Text(Preferences().userName.prefix(1).uppercased())
                                    .font(.title2)
                                }
                                .padding(8)
                                .background(Circle().stroke()))
    }
    
    func makeOffer(result: NWBrowser.Result, listing: Listing) {
        sharedConnection = PeerConnection(endpoint: result.endpoint,
            interface: result.interfaces.first,
            passcode: "1155",
            delegate: manager)
        
        selectedListing = listing
        negotiating = true
    }
    
    func postListing() {
        let listingJsonString = createListing().toJSON().description
        if let listener = sharedListener {
            // If your app is already listening, just update listing.
            listener.resetName(listingJsonString)
        } else {
            // If your app is not yet listening, start a new listener.
            sharedListener = PeerListener(name: listingJsonString, passcode: "1155", delegate: manager)
        }
        clearFields()
    }
    
    func createListing() -> Listing {
        let prefs = Preferences()
        let listing = Listing()
        listing.amount = amount
        listing.price = price
        listing.name = prefs.userName
        return listing
    }
    
    func clearFields() {
        self.amount = ""
        self.price = ""
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}


struct PlainGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .center) {
            configuration.label
            configuration.content
        }
        .padding(10)
    }
}
