import SwiftUI

/// 链接预览卡片视图
struct LinkPreviewCard: View {
    let preview: LinkPreviewFetcher.LinkPreview
    
    var body: some View {
        Link(destination: preview.url) {
            HStack(spacing: 12) {
                // 预览图
                if let imageURL = preview.imageURL {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // 文字内容
                VStack(alignment: .leading, spacing: 4) {
                    if let siteName = preview.siteName {
                        Text(siteName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let title = preview.title {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(2)
                            .foregroundStyle(.primary)
                    }
                    
                    if let desc = preview.description {
                        Text(desc)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
            }
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
