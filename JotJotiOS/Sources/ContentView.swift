import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Jot.updatedAt, order: .reverse) private var jots: [Jot]
    @State private var currentIndex = 0
    @State private var dragOffset: CGFloat = 0
    @State private var showList = false
    @State private var keyboardHeight: CGFloat = 0
    
    // 触觉反馈生成器
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 背景
                Color(.systemGroupedBackground)
                    .ignoresSafeArea(.all)
                
                // 背后的列表（始终存在，showList 时显示）
                if !jots.isEmpty {
                    listView(in: geo)
                        .opacity(showList ? 1 : 0)
                }
                
                // 前景的卡片
                ZStack {
                    if jots.isEmpty {
                        emptyState
                    } else {
                        cardStack(in: geo)
                    }
                }
                .scaleEffect(showList ? 0.85 : 1)
                .offset(y: showList ? -geo.size.height * 0.35 : 0)
                .opacity(showList ? 0.6 : 1)
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showList)
                .allowsHitTesting(!showList)
                
                // 顶部工具栏
                topBar
            }
        }
        .onAppear {
            setupKeyboardObservers()
            impactFeedback.prepare()
            selectionFeedback.prepare()
        }
    }
    
    // MARK: - 顶部工具栏
    private var topBar: some View {
        VStack {
            HStack {
                Button(action: toggleList) {
                    Image(systemName: showList ? "xmark" : "list.bullet")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                }
                .disabled(jots.isEmpty)
                
                Spacer()
                
                Text("JotJot")
                    .font(.system(size: 17, weight: .semibold))
                
                Spacer()
                
                Button(action: createNewJot) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 8)
            
            Spacer()
        }
    }
    
    private func toggleList() {
        impactFeedback.impactOccurred(intensity: 0.5)
        // 收起键盘
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            showList.toggle()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 28) {
            Image(systemName: "note.text")
                .font(.system(size: 64, weight: .thin))
                .foregroundStyle(.tertiary)
            
            VStack(spacing: 10) {
                Text("开始记录")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                Text("想到就记，记完就走")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }
            
            Button(action: createNewJot) {
                Label("新建笔记", systemImage: "plus.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Color.blue, in: Capsule())
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.top, 4)
        }
    }
    
    @ViewBuilder
    private func cardStack(in geo: GeometryProxy) -> some View {
        let screenWidth = geo.size.width
        // 安全获取当前索引
        let safeCurrentIndex = min(max(0, currentIndex), max(0, jots.count - 1))
        
        ZStack {
            // 点击背景收起键盘
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            
            // 使用 jot.id 作为标识，避免索引越界
            ForEach(Array(jots.enumerated()), id: \.element.id) { index, jot in
                // 只显示当前卡片附近的几张
                if abs(index - safeCurrentIndex) <= 2 {
                    let offset = index - safeCurrentIndex
                    let dragProgress = dragOffset / screenWidth
                    
                    JotCardView(jot: jot, keyboardHeight: keyboardHeight, onDelete: {
                        deleteJot(jot: jot)
                    })
                    .zIndex(Double(-abs(offset)))
                    .offset(x: cardXOffset(for: offset, dragProgress: dragProgress, screenWidth: screenWidth))
                    .scaleEffect(cardScale(for: offset, dragProgress: dragProgress))
                    .offset(y: cardYOffset(for: offset, dragProgress: dragProgress))
                    .opacity(cardOpacity(for: offset, dragProgress: dragProgress))
                    .rotation3DEffect(
                        .degrees(cardRotation(for: offset, dragProgress: dragProgress)),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0.5
                    )
                }
            }
        }
        .gesture(jots.isEmpty ? nil : swipeGesture)
        .onChange(of: jots.count) { oldCount, newCount in
            // 当笔记数量变化时，确保 currentIndex 有效
            if newCount == 0 {
                currentIndex = 0
            } else if currentIndex >= newCount {
                currentIndex = newCount - 1
            }
        }
    }
    
    // MARK: - 卡片动效计算
    
    private func cardXOffset(for offset: Int, dragProgress: CGFloat, screenWidth: CGFloat) -> CGFloat {
        if offset == 0 {
            return dragOffset
        }
        // 相邻卡片跟随移动，产生视差效果
        let parallaxFactor: CGFloat = 0.3
        return CGFloat(offset) * 30 + dragOffset * parallaxFactor
    }
    
    private func cardScale(for offset: Int, dragProgress: CGFloat) -> CGFloat {
        let baseScale: CGFloat = offset == 0 ? 1.0 : 0.88 - CGFloat(abs(offset) - 1) * 0.04
        
        if offset == 0 {
            // 当前卡片：拖动时轻微缩小
            return 1.0 - abs(dragProgress) * 0.05
        } else if offset == 1 && dragProgress < 0 {
            // 右边卡片：向左滑时放大
            return baseScale + abs(dragProgress) * 0.12
        } else if offset == -1 && dragProgress > 0 {
            // 左边卡片：向右滑时放大
            return baseScale + abs(dragProgress) * 0.12
        }
        return baseScale
    }
    
    private func cardYOffset(for offset: Int, dragProgress: CGFloat) -> CGFloat {
        let baseOffset = CGFloat(abs(offset)) * 12
        
        if offset == 0 {
            return 0
        } else if offset == 1 && dragProgress < 0 {
            return baseOffset * (1 - abs(dragProgress))
        } else if offset == -1 && dragProgress > 0 {
            return baseOffset * (1 - abs(dragProgress))
        }
        return baseOffset
    }
    
    private func cardOpacity(for offset: Int, dragProgress: CGFloat) -> Double {
        let baseOpacity: Double = offset == 0 ? 1.0 : 0.5 - Double(abs(offset) - 1) * 0.15
        
        if offset == 0 {
            return 1.0 - abs(Double(dragProgress)) * 0.2
        } else if offset == 1 && dragProgress < 0 {
            return baseOpacity + abs(Double(dragProgress)) * 0.5
        } else if offset == -1 && dragProgress > 0 {
            return baseOpacity + abs(Double(dragProgress)) * 0.5
        }
        return max(0.2, baseOpacity)
    }
    
    private func cardRotation(for offset: Int, dragProgress: CGFloat) -> Double {
        if offset == 0 {
            return Double(dragProgress) * -8
        }
        return 0
    }
    
    // MARK: - 手势处理
    
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
                    dragOffset = value.translation.width
                }
            }
            .onEnded(handleSwipeEnd)
    }
    
    private func handleSwipeEnd(_ value: DragGesture.Value) {
        // 空数组保护
        guard !jots.isEmpty else {
            dragOffset = 0
            return
        }
        
        let threshold: CGFloat = 60
        let velocity = value.predictedEndTranslation.width - value.translation.width
        
        // 确保 currentIndex 在有效范围内
        let safeCurrentIndex = min(max(0, currentIndex), jots.count - 1)
        var didSwitch = false
        var newIndex = safeCurrentIndex
        
        if (value.translation.width > threshold || velocity > 150) && safeCurrentIndex > 0 {
            newIndex = safeCurrentIndex - 1
            didSwitch = true
        } else if (value.translation.width < -threshold || velocity < -150) && safeCurrentIndex < jots.count - 1 {
            newIndex = safeCurrentIndex + 1
            didSwitch = true
        }
        
        // 触觉反馈
        if didSwitch {
            impactFeedback.impactOccurred(intensity: 0.6)
        } else if abs(value.translation.width) > 20 {
            selectionFeedback.selectionChanged()
        }
        
        // 丝滑弹簧动画
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0)) {
            currentIndex = newIndex
            dragOffset = 0
        }
    }
    
    // MARK: - 背后的列表视图
    
    private func listView(in geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(jots.enumerated()), id: \.element.id) { index, jot in
                            listRow(jot: jot, index: index, isSelected: index == currentIndex)
                                .id(index)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 120)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation {
                            proxy.scrollTo(currentIndex, anchor: .center)
                        }
                    }
                }
            }
        }
    }
    
    private func listRow(jot: Jot, index: Int, isSelected: Bool) -> some View {
        Button {
            impactFeedback.impactOccurred(intensity: 0.5)
            currentIndex = index
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                showList = false
            }
        } label: {
            HStack(spacing: 14) {
                Circle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        if jot.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.orange)
                        }
                        Text(jot.content.components(separatedBy: .newlines).first ?? "新笔记")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                    
                    Text(jot.updatedAt, style: .relative)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 底部栏
    
    private var bottomBar: some View {
        HStack {
            if !jots.isEmpty {
                pageIndicator
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
    }
    
    private var pageIndicator: some View {
        let safeIndex = min(currentIndex, max(0, jots.count - 1))
        return HStack(spacing: 6) {
            ForEach(0..<min(jots.count, 5), id: \.self) { i in
                Circle()
                    .fill(i == safeIndex ? Color.primary : Color.secondary.opacity(0.3))
                    .frame(width: i == safeIndex ? 8 : 6, height: i == safeIndex ? 8 : 6)
                    .animation(.spring(response: 0.3), value: safeIndex)
            }
            if jots.count > 5 {
                Text("+\(jots.count - 5)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - 操作
    
    private func createNewJot() {
        impactFeedback.impactOccurred(intensity: 0.5)
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            let jot = Jot(content: "")
            modelContext.insert(jot)
            currentIndex = 0
        }
    }
    
    private func deleteJot(jot: Jot) {
        // 找到当前 jot 的索引
        guard let index = jots.firstIndex(where: { $0.id == jot.id }) else { return }
        
        // 计算删除后的新索引
        let newCount = jots.count - 1
        let newIndex: Int
        if newCount == 0 {
            newIndex = 0
        } else if currentIndex >= newCount {
            newIndex = newCount - 1
        } else if index < currentIndex {
            newIndex = currentIndex - 1
        } else {
            newIndex = currentIndex
        }
        
        // 触感反馈
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentIndex = newIndex
            modelContext.delete(jot)
        }
    }
    
    // MARK: - 键盘处理
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = keyboardFrame.height
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = 0
            }
        }
    }
}
