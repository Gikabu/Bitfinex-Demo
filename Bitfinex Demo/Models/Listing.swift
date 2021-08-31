//
//  Listing.swift
//  Bitfinex Demo
//
//  Created by Jonathan Gikabu on 29/08/2021.
//

import Foundation
import SwiftyJSON

class Listing {
    var name: String = ""
    var price: String = ""
    var amount: String = ""
    
    convenience required init(json: JSON) {
        self.init()
        name = json["name"].stringValue
        price = json["price"].stringValue
        amount = json["amount"].stringValue
    }
    
    func toJSON() -> JSON {
        return JSON(toDictionary())
    }
    
    func toDictionary() -> [String:String] {
        var dictionary = [String:String]()
        dictionary["name"] = name
        dictionary["price"] = price
        dictionary["amount"] = amount
        return dictionary
    }
}
