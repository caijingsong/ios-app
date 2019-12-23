import Foundation

internal struct RelationshipRequest: Encodable {
    let user_id: String
    let full_name: String?
    let action: RelationshipAction
}

internal enum RelationshipAction: String, Codable {
    case ADD
    case REMOVE
    case UPDATE
    case BLOCK
    case UNBLOCK
}
