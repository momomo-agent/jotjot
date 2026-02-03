import Foundation
import SwiftData

@Model
public final class Jot {
    @Attribute(.unique) public var id: UUID
    public var content: String
    public var isPinned: Bool
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(content: String = "", isPinned: Bool = false) {
        self.id = UUID()
        self.content = content
        self.isPinned = isPinned
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
