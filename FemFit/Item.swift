//
//  Item.swift
//  FemFit
//
//  Created by André Pels on 19.03.26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
