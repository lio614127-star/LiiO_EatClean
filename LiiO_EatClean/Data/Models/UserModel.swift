import Foundation

struct UserModel: Identifiable, Codable {
    let id: UUID
    var name: String
    var age: Double
    var gender: String
    var height: Double
    var weight: Double
    var goalType: String
    var dailyCalorieTarget: Double
    
    init(id: UUID = UUID(), name: String = "", age: Double = 0.0, gender: String = "male", height: Double = 0.0, weight: Double = 0.0, goalType: String = "", dailyCalorieTarget: Double = 2000.0) {
        self.id = id
        self.name = name
        self.age = age
        self.gender = gender
        self.height = height
        self.weight = weight
        self.goalType = goalType
        self.dailyCalorieTarget = dailyCalorieTarget
    }
}
