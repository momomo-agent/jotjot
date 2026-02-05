import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation

struct JotCardView: View {
    @Bindable var jot: Jot
    var keyboardHeight: CGFloat = 0
    var onDelete: (() -> Void)? = nil
    
    @FocusState private var isFocused: Bool
    @State private var showCopied = false
    @State private var showDeleteConfirm = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var isDropTargeted = false
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var linkPreviews: [LinkPreviewFetcher.LinkPreview] = []
    
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    private let linkFetcher = LinkPreviewFetcher()
    
    var body: some View {
        VStack(spacing: 0) {
            cardEditor
            linkPreviewSection
            cardFooter
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 1, y: 1)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        .shadow(color: .black.opacity(0.08), radius: 24, y: 12)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, keyboardHeight > 0 ? 8 : 20)
        .onAppear { impactFeedback.prepare() }
        .onChange(of: jot.content) { _, newValue in
            detectLinks(in: newValue)
        }
        .task {
            detectLinks(in: jot.content)
        }
    }
    
    // MARK: - 媒体网格
    @ViewBuilder
    private var mediaGrid: some View {
        if !jot.mediaItems.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(jot.mediaItems) { item in
                        mediaItemView(item)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 8)
            }
        }
    }
    
    private func mediaItemView(_ item: MediaItem) -> some View {
        Group {
            if item.type == .image, let uiImage = UIImage(data: item.data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if item.type == .video, let thumb = item.thumbnail, let uiImage = UIImage(data: thumb) {
                ZStack {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .contextMenu {
            Button(role: .destructive) {
                removeMedia(item)
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
        .draggable(item.data)
    }
    
    // MARK: - 拖放覆盖层
    private var dropOverlay: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .stroke(Color.accentColor, lineWidth: 3)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.accentColor.opacity(0.1))
            )
            .opacity(isDropTargeted ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: isDropTargeted)
    }
    
    // MARK: - 背景
    private var cardBackground: some View {
        ZStack {
            // 卡片填充 - light/dark 都有实体感
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.secondarySystemBackground))
            
            // 顶部高光 - 适配 light/dark
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.primary.opacity(0.1), .primary.opacity(0.05), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.5
                )
        }
    }
    
    // MARK: - 底部工具栏
    private var cardFooter: some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                Text(jot.updatedAt, format: .dateTime.month().day().hour().minute())
                Text("·")
                Text("\(jot.content.count) 字")
            }
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(.tertiary)
            
            Spacer()
            
            HStack(spacing: 20) {
                shareButton
                pinButton
                photoPickerButton
                micButton
                deleteButton
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
    
    // MARK: - 按钮
    private var shareButton: some View {
        ShareLink(item: jot.content) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("分享")
    }
    
    private var pinButton: some View {
        Button(action: togglePin) {
            Image(systemName: jot.isPinned ? "pin.fill" : "pin")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(jot.isPinned ? .orange : .secondary)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(jot.isPinned ? "取消固定" : "固定")
    }
    
    private var photoPickerButton: some View {
        PhotosPicker(selection: $selectedPhotos, matching: .any(of: [.images, .videos])) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("添加图片或视频")
        .onChange(of: selectedPhotos) { _, newItems in
            Task { await loadSelectedPhotos(newItems) }
        }
    }
    
    private var micButton: some View {
        Button(action: toggleVoiceInput) {
            Image(systemName: speechRecognizer.isRecording ? "waveform" : "mic")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(speechRecognizer.isRecording ? .red : .secondary)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(speechRecognizer.isRecording ? "停止录音" : "语音输入")
    }
    
    private var deleteButton: some View {
        Button(action: { showDeleteConfirm = true }) {
            Image(systemName: "trash")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("删除")
        .confirmationDialog("删除这条笔记？", isPresented: $showDeleteConfirm) {
            Button("删除", role: .destructive) {
                impactFeedback.impactOccurred(intensity: 0.6)
                onDelete?()
            }
            Button("取消", role: .cancel) {}
        }
    }
    
    // MARK: - 编辑器
    private var cardEditor: some View {
        MarkdownTextEditor(
            text: $jot.content,
            mediaItems: jot.mediaItems
        )
        .frame(minHeight: 200)
        .onChange(of: jot.content) { jot.updatedAt = Date() }
    }
    
    // MARK: - 操作
    private func togglePin() {
        impactFeedback.impactOccurred(intensity: 0.5)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            jot.isPinned.toggle()
        }
    }
    
    private func toggleVoiceInput() {
        impactFeedback.impactOccurred(intensity: 0.5)
        speechRecognizer.onTranscriptionComplete = { text in
            if jot.content.isEmpty {
                jot.content = text
            } else {
                jot.content += "\n" + text
            }
            jot.updatedAt = Date()
        }
        speechRecognizer.toggleRecording()
    }
    
    // MARK: - 媒体处理
    private func loadSelectedPhotos(_ items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                // 只支持图片的图文混排
                guard !item.supportedContentTypes.contains(.movie) else { continue }
                
                let mediaItem = MediaItem(type: .image, data: data, thumbnail: nil)
                
                await MainActor.run {
                    // 添加到媒体列表
                    jot.mediaItems.append(mediaItem)
                    
                    // 在文本末尾插入图片标记
                    let imageTag = "\n![](\\(mediaItem.id.uuidString))\n"
                    jot.content += imageTag
                    jot.updatedAt = Date()
                    
                    impactFeedback.impactOccurred(intensity: 0.4)
                }
            }
        }
        selectedPhotos = []
    }
    
    private func generateVideoThumbnail(_ data: Data) async -> Data? {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".mov")
        try? data.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        let asset = AVAsset(url: tempURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        if let cgImage = try? generator.copyCGImage(
            at: .zero, actualTime: nil
        ) {
            let uiImage = UIImage(cgImage: cgImage)
            return uiImage.jpegData(compressionQuality: 0.7)
        }
        return nil
    }
    
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                    if let data = data {
                        let item = MediaItem(type: .image, data: data)
                        DispatchQueue.main.async {
                            withAnimation { jot.mediaItems.append(item) }
                            jot.updatedAt = Date()
                            impactFeedback.impactOccurred(intensity: 0.5)
                        }
                    }
                }
            }
        }
        return true
    }
    
    private func removeMedia(_ item: MediaItem) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            jot.mediaItems.removeAll { $0.id == item.id }
            jot.updatedAt = Date()
        }
        impactFeedback.impactOccurred(intensity: 0.4)
    }
    
    // MARK: - 链接预览
    
    @ViewBuilder
    private var linkPreviewSection: some View {
        if !linkPreviews.isEmpty {
            VStack(spacing: 8) {
                ForEach(linkPreviews, id: \.url) { preview in
                    LinkPreviewCard(preview: preview)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
    }
    
    private func detectLinks(in text: String) {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(text.startIndex..., in: text)
        
        var urls: [URL] = []
        detector?.enumerateMatches(in: text, range: range) { match, _, _ in
            if let url = match?.url {
                urls.append(url)
            }
        }
        
        // 只取前 3 个链接
        let urlsToFetch = Array(urls.prefix(3))
        
        Task {
            var previews: [LinkPreviewFetcher.LinkPreview] = []
            for url in urlsToFetch {
                if let preview = await linkFetcher.fetchPreview(for: url) {
                    previews.append(preview)
                }
            }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    linkPreviews = previews
                }
            }
        }
    }
}

// MARK: - 按钮样式
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
