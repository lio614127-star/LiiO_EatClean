import Foundation

struct WeightEntryModel: Identifiable, Codable {
    let id: UUID
    var date: Date
    var weight: Double
    
    init(id: UUID = UUID(), date: Date = Date(), weight: Double = 0.0) {
        self.id = id
        self.date = date
        self.weight = weight
    }
}
