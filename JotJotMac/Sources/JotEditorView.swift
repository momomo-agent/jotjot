import SwiftUI
import AppKit
import UniformTypeIdentifiers
import AVFoundation

struct JotEditorView: View {
    @Bindable var jot: Jot
    @FocusState private var isFocused: Bool
    @State private var showCopied = false
    @State private var isDropTargeted = false
    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    var body: some View {
        VStack(spacing: 0) {
            editorToolbar
            Divider()
            mediaGrid
            editorArea
        }
        .frame(minWidth: 300)
        .overlay(dropOverlay)
        .onDrop(of: [.image, .movie, .fileURL], isTargeted: $isDropTargeted, perform: handleDrop)
        .onAppear { isFocused = true }
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
                .padding(12)
            }
            Divider()
        }
    }
    
    private func mediaItemView(_ item: MediaItem) -> some View {
        Group {
            if item.type == .image, let nsImage = NSImage(data: item.data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if item.type == .video {
                ZStack {
                    if let thumb = item.thumbnail, let nsImage = NSImage(data: thumb) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .draggable(item.data)
        .contextMenu {
            Button("删除", role: .destructive) { removeMedia(item) }
        }
    }
    
    // MARK: - 拖放覆盖层
    private var dropOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.accentColor, lineWidth: 2)
            .background(Color.accentColor.opacity(0.1))
            .opacity(isDropTargeted ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: isDropTargeted)
    }
    
    // MARK: - 编辑器区域
    private var editorArea: some View {
        AdvancedTextEditor(text: $jot.content) {
            WindowManager.shared.hide()
        }
        .focused($isFocused)
        .onChange(of: jot.content) {
            jot.updatedAt = Date()
        }
    }
    
    // MARK: - 工具栏
    private var editorToolbar: some View {
        HStack(spacing: 16) {
            Button(action: togglePin) {
                Image(systemName: jot.isPinned ? "pin.fill" : "pin")
                    .foregroundStyle(jot.isPinned ? .orange : .secondary)
            }
            .buttonStyle(.plain)
            .help("固定 ⌘P")
            
            Button(action: addMedia) {
                Image(systemName: "photo.on.rectangle.angled")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("添加图片/视频")
            
            Button(action: toggleVoiceInput) {
                Image(systemName: speechRecognizer.isRecording ? "waveform" : "mic")
                    .foregroundStyle(speechRecognizer.isRecording ? .red : .secondary)
            }
            .buttonStyle(.plain)
            .help("语音输入")
            
            Spacer()
            
            Text("\(jot.content.count) 字")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    // MARK: - 操作
    private func togglePin() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            jot.isPinned.toggle()
        }
    }
    
    private func toggleVoiceInput() {
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
    
    private func addMedia() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image, .movie]
        panel.allowsMultipleSelection = true
        
        if panel.runModal() == .OK {
            for url in panel.urls {
                loadMedia(from: url)
            }
        }
    }
    
    private func loadMedia(from url: URL) {
        guard let data = try? Data(contentsOf: url) else { return }
        
        let uti = UTType(filenameExtension: url.pathExtension)
        let isVideo = uti?.conforms(to: .movie) ?? false
        
        var thumbnail: Data? = nil
        if isVideo {
            thumbnail = generateThumbnail(url)
        }
        
        let item = MediaItem(
            type: isVideo ? .video : .image,
            data: data,
            thumbnail: thumbnail
        )
        
        withAnimation {
            jot.mediaItems.append(item)
            jot.updatedAt = Date()
        }
    }
    
    private func generateThumbnail(_ url: URL) -> Data? {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        if let cgImage = try? generator.copyCGImage(at: .zero, actualTime: nil) {
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: 120, height: 120))
            return nsImage.tiffRepresentation
        }
        return nil
    }
    
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, _ in
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            loadMedia(from: url)
                        }
                    }
                }
            }
        }
        return true
    }
    
    private func removeMedia(_ item: MediaItem) {
        withAnimation {
            jot.mediaItems.removeAll { $0.id == item.id }
            jot.updatedAt = Date()
        }
    }
}
