import Foundation

struct UserProfileMemory: Codable {
    var preferences: [String] = []
    var dislikes: [String] = []
    var notes: [String] = []
}
