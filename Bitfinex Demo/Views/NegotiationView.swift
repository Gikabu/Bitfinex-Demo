//
//  NegotiationView.swift
//  Bitfinex Demo
//
//  Created by Jonathan Gikabu on 30/08/2021.
//

import SwiftUI

struct NegotiationView: View {
    @EnvironmentObject var manager: ExchangeManager
    @Binding var isPresented: Bool
    @State var listing: Listing
    @State private var price: String = ""
    @State private var amount: String = ""
    @State private var ready: Bool = false
    
    var isSale: Bool {
        return listing.name == Preferences().userName
    }
    
    var counterOfferButtonDisabled: Bool {
        return price.isEmptyOrWhitespace || amount.isEmptyOrWhitespace || !ready
    }
    
    var body: some View {
        VStack {
            HStack {
                ZStack {
                    Text(isSale ? "Selling" : "Buying")
                        .fontWeight(.semibold)
                    
                    HStack {
                        Spacer()
                        Button(action: { quit() }, label: {
                            Text("Quit")
                                .bold()
                        })
                    }
                    .padding(.horizontal)
                }
            }
            .frame(height: 45)
            .background(Color(UIColor.secondarySystemBackground))
            
            GroupBox {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Price USD: \(listing.price)")
                        TextField("Propose price", text: $price)
                            .padding(8)
                            .keyboardType(.numberPad)
                            .background(RoundedRectangle(cornerRadius: 12).stroke().foregroundColor(.secondary))
                            .disabled(!ready)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Amount BTC: \(listing.amount)")
                        TextField("Change amount", text: $amount)
                            .padding(8)
                            .keyboardType(.numberPad)
                            .background(RoundedRectangle(cornerRadius: 12).stroke().foregroundColor(.secondary))
                            .disabled(!ready)
                    }
                }
                
                Divider()
                    .padding(.vertical, 10)
                
                HStack {
                    if isSale {
                        Button(action: { decide(accept: false) }, label: {
                            VStack {
                                Text("Reject".uppercased())
                                    .font(.caption)
                                    .padding(8)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal)
                            .background(RoundedRectangle(cornerRadius: 20).foregroundColor(.red))
                        })
                        .disabled(!ready)
                    }
                    
                    Button(action: { counterOffer() }, label: {
                        VStack {
                            Text("Counter Offer".uppercased())
                                .font(.caption)
                                .padding(8)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                        .background(RoundedRectangle(cornerRadius: 20))
                    })
                    .disabled(counterOfferButtonDisabled)
                    
                    Button(action: { decide(accept: true) }, label: {
                        VStack {
                            Text("Accept".uppercased())
                                .font(.caption)
                                .padding(8)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                        .background(RoundedRectangle(cornerRadius: 20).foregroundColor(.green))
                    })
                    .disabled(!ready)
                }
            }
            
            VStack {
                ScrollView {
                    VStack {
                        ForEach(manager.thread, id: \.id) { exchange in
                            Button(action: {}, label: {
                                messageRow(exchange: exchange)
                                    .font(.subheadline)
                            })
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            
                            Divider()
                        }
                    }
                }
            }
            .frame(minHeight: 500)
        }
        .onAppear(perform: {
            if !isSale {
                sharedConnection?.sendExchangeContent(Exchange.buyerIntent(listing: listing).toJSON().description)
                ready = true
            }
        })
    }
    
    func sendMessage(exchange: Exchange) {
        sharedConnection?.sendExchangeContent(exchange.toJSON().description)
    }
    
    func quit() {
        let exc = Exchange()
        exc.amount = listing.amount
        exc.price = listing.price
        exc.type = ExchangeType.resign.rawValue
        exc.proponent = Preferences().userName
        exc.id = UUID().uuidString
        sendMessage(exchange: exc)
        isPresented = false
    }
    
    func counterOffer() {
        let exc = Exchange()
        exc.amount = amount
        exc.price = price
        exc.type = ExchangeType.counter.rawValue
        exc.proponent = Preferences().userName
        exc.id = UUID().uuidString
        exc.cycle = 2
        sendMessage(exchange: exc)
    }
    
    func decide(accept: Bool) {
        let exc = Exchange()
        exc.amount = counterOfferButtonDisabled ? listing.amount : amount
        exc.price = counterOfferButtonDisabled ? listing.price : price
        exc.type = accept ? ExchangeType.accept.rawValue : ExchangeType.reject.rawValue
        exc.proponent = Preferences().userName
        exc.id = UUID().uuidString
        exc.cycle = 2
        sendMessage(exchange: exc)
        ready = false
    }
    
    func summary(amount: String, price: String) {
        let exc = Exchange()
        exc.amount = amount
        exc.price = price
        exc.type = ExchangeType.summary.rawValue
        exc.proponent = Preferences().userName
        exc.id = UUID().uuidString
        exc.cycle = 2
        sendMessage(exchange: exc)
    }
    
    @ViewBuilder
    private func messageRow(exchange: Exchange) -> some View {
        switch exchange.type {
        case ExchangeType.intent.rawValue:
            Text("\(exchange.proponent) is preparing a bid.")
        case ExchangeType.accept.rawValue:
            VStack {
                Text("\(exchange.proponent) accepted your \(exchange.cycle > 1 ? "counter offer" : "offer"). ")
                Text("You've \(isSale ? "sold" : "bought") BTC\(exchange.amount) for USD\(exchange.price)")
                .onAppear(perform: {
                    summary(amount: exchange.amount, price: exchange.price)
                    clearFields()
                })
            }
        case ExchangeType.reject.rawValue:
            Text("\(exchange.proponent) rejected your \(exchange.cycle > 1 ? "counter offer" : "offer").")
        case ExchangeType.counter.rawValue:
            Text("\(exchange.proponent) proposes \(isSale ? "buying" : "selling") BTC\(exchange.amount) @ USD\(exchange.price) \(isSale ? "from you" : "to you")")
                .onAppear(perform: {
                    ready = true
                    amount = exchange.amount
                    price = exchange.price
                })
        case ExchangeType.resign.rawValue:
            Text("\(exchange.proponent) left negotiations.")
                .onAppear(perform: {
                    ready = false
                    clearFields()
                })
        case ExchangeType.summary.rawValue:
            Text("You've \(isSale ? "sold" : "bought") BTC\(exchange.amount) for USD\(exchange.price)")
        default:
            EmptyView().hidden()
        }
    }
    
    func clearFields() {
        self.amount = ""
        self.price = ""
    }
}

struct NegotiationView_Previews: PreviewProvider {
    static var previews: some View {
        NegotiationView(isPresented: .constant(false), listing: Listing())
    }
}
