import Foundation
import SwiftData

@Model
class Item: Identifiable {
    var id: UUID
    var timestamp: Date
    var imagePath: String?

    init(timestamp: Date, imagePath: String? = nil) {
        self.id = UUID()
        self.timestamp = timestamp
        self.imagePath = imagePath
    }
}
