import Foundation
import SwiftData

@Model
public final class Jot {
    @Attribute(.unique) public var id: UUID
    public var content: String
    public var isPinned: Bool
    public var createdAt: Date
    public var updatedAt: Date
    
    // 媒体附件 - 存储为 Data 数组
    @Attribute(.externalStorage) public var mediaItems: [MediaItem]
    
    public init(content: String = "", isPinned: Bool = false) {
        self.id = UUID()
        self.content = content
        self.isPinned = isPinned
        self.createdAt = Date()
        self.updatedAt = Date()
        self.mediaItems = []
    }
}

// MARK: - 媒体项
public struct MediaItem: Codable, Identifiable, Hashable {
    public var id: UUID
    public var type: MediaType
    public var data: Data
    public var thumbnail: Data?  // 视频缩略图
    public var createdAt: Date
    
    public init(type: MediaType, data: Data, thumbnail: Data? = nil) {
        self.id = UUID()
        self.type = type
        self.data = data
        self.thumbnail = thumbnail
        self.createdAt = Date()
    }
}

public enum MediaType: String, Codable {
    case image
    case video
}
