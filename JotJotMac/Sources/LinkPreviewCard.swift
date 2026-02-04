import SwiftUI

/// Mac 版链接预览卡片
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
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                // 文字内容
                VStack(alignment: .leading, spacing: 2) {
                    if let siteName = preview.siteName {
                        Text(siteName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let title = preview.title {
                        Text(title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
            }
            .padding(10)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
