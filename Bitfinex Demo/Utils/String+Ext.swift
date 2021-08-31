//
//  String+Ext.swift
//  Bitfinex Demo
//
//  Created by Jonathan Gikabu on 29/08/2021.
//

import Foundation

extension String {
    var isEmptyOrWhitespace: Bool {
        let whitespace = CharacterSet.whitespacesAndNewlines
        return self.trimmingCharacters(in: whitespace).isEmpty
    }
}
