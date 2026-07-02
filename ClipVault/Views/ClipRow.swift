import SwiftUI
import AppKit

struct ClipRow: View {
    let item: ClipItem
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            if item.type == .image, let thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Image(systemName: iconName)
                    .frame(width: 16)
                    .foregroundStyle(isSelected ? Color.white : .secondary)
            }

            Text(item.preview)
                .lineLimit(1)
                .foregroundStyle(isSelected ? Color.white : .primary)

            Spacer(minLength: 0)

            if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.caption)
                    .foregroundStyle(isSelected ? Color.white : .orange)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color.accentColor : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
    }

    private var thumbnail: NSImage? {
        guard let imagePath = item.imagePath else { return nil }
        return NSImage(contentsOfFile: imagePath)
    }

    private var iconName: String {
        switch item.type {
        case .text: return "doc.text"
        case .url: return "link"
        case .image: return "photo"
        case .file: return "doc.on.doc"
        }
    }
}
