import Foundation
import SwiftData

enum ClipType: String, Codable {
    case text
    case url
    case image
    case file
}

@Model
final class ClipItem {
    @Attribute(.unique) var id: UUID
    var type: ClipType
    var textContent: String?
    var imagePath: String?
    var filePaths: [String]? = nil
    var preview: String
    var createdAt: Date
    var isPinned: Bool
    var sourceApp: String?
    var contentHash: String = ""

    init(
        id: UUID = UUID(),
        type: ClipType,
        textContent: String? = nil,
        imagePath: String? = nil,
        filePaths: [String]? = nil,
        preview: String,
        createdAt: Date = Date(),
        isPinned: Bool = false,
        sourceApp: String? = nil,
        contentHash: String
    ) {
        self.id = id
        self.type = type
        self.textContent = textContent
        self.imagePath = imagePath
        self.filePaths = filePaths
        self.preview = preview
        self.createdAt = createdAt
        self.isPinned = isPinned
        self.sourceApp = sourceApp
        self.contentHash = contentHash
    }
}
