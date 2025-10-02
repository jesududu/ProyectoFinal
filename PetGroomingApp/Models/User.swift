import Foundation
import FirebaseFirestore

struct User: Codable, Identifiable {
    let id: String
    let name: String
    let email: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
    }
}









