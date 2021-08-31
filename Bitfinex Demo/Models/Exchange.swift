//
//  Event.swift
//  Bitfinex Demo
//
//  Created by Jonathan Gikabu on 30/08/2021.
//

import Foundation
import SwiftyJSON

enum ExchangeType: Int {
    case intent = 0
    case accept = 1
    case reject = 2
    case counter = 3
    case resign = 4
    case summary = 5
    case none
}

class Exchange {
    var id: String = ""
    var proponent: String = ""
    var price: String = ""
    var amount: String = ""
    var type: Int = -1
    var cycle: Int = 0
    
    convenience required init(json: JSON) {
        self.init()
        id = json["id"].stringValue
        proponent = json["proponent"].stringValue
        price = json["price"].stringValue
        amount = json["amount"].stringValue
        type = json["type"].intValue
        cycle = json["cycle"].intValue
    }
    
    func toJSON() -> JSON {
        return JSON(toDictionary())
    }
    
    func toDictionary() -> [String:Any] {
        var dictionary = [String:Any]()
        dictionary["id"] = id
        dictionary["proponent"] = proponent
        dictionary["price"] = price
        dictionary["amount"] = amount
        dictionary["type"] = type
        dictionary["cycle"] = cycle
        return dictionary
    }
    
    static func buyerIntent(listing: Listing) -> Exchange {
        let item = Exchange()
        item.id = UUID().uuidString
        item.type = ExchangeType.intent.rawValue
        item.price = listing.price
        item.amount = listing.amount
        item.proponent = Preferences().userName
        item.cycle = 0
        return item
    }
}
