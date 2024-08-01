//
//  Item.swift
//  fashion_sense
//
//  Created by Lakshya Agarwal on 1/8/24.
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
