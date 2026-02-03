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
        NavigationStack {
            ZStack {
                // 渐变背景 - 放在最外层确保覆盖全屏
                Color(.systemGroupedBackground)
                    .ignoresSafeArea(.all)
                
                GeometryReader { geo in
                    ZStack {
                        if jots.isEmpty {
                            emptyState
                        } else {
                            cardStack(in: geo)
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomBar
                    .padding(.bottom, keyboardHeight > 0 ? 0 : 0)
            }
            .navigationTitle("JotJot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { showList = true }) {
                        Image(systemName: "list.bullet")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: createNewJot) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showList) {
                JotListSheet(jots: jots, currentIndex: $currentIndex)
            }
        }
        .onAppear {
            setupKeyboardObservers()
            impactFeedback.prepare()
            selectionFeedback.prepare()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "note.text")
                .font(.system(size: 72, weight: .thin))
                .foregroundStyle(.tertiary)
                .symbolEffect(.pulse.byLayer, options: .repeating)
            
            VStack(spacing: 8) {
                Text("开始记录")
                    .font(.title2.weight(.medium))
                Text("想到就记，记完就走")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Button(action: createNewJot) {
                Label("新建笔记", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.blue, in: Capsule())
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.top, 8)
        }
    }
    
    @ViewBuilder
    private func cardStack(in geo: GeometryProxy) -> some View {
        let screenWidth = geo.size.width
        
        ZStack {
            ForEach(visibleIndices, id: \.self) { index in
                let offset = index - currentIndex
                let dragProgress = dragOffset / screenWidth
                
                JotCardView(jot: jots[index], keyboardHeight: keyboardHeight, onDelete: {
                    deleteJot(at: index)
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
        .gesture(swipeGesture)
    }
    
    private var visibleIndices: [Int] {
        let range = max(0, currentIndex - 2)...min(jots.count - 1, currentIndex + 2)
        return Array(range)
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
        let threshold: CGFloat = 60
        let velocity = value.predictedEndTranslation.width - value.translation.width
        
        var didSwitch = false
        var newIndex = currentIndex
        
        if (value.translation.width > threshold || velocity > 150) && currentIndex > 0 {
            newIndex = currentIndex - 1
            didSwitch = true
        } else if (value.translation.width < -threshold || velocity < -150) && currentIndex < jots.count - 1 {
            newIndex = currentIndex + 1
            didSwitch = true
        }
        
        // 触觉反馈
        if didSwitch {
            impactFeedback.impactOccurred(intensity: 0.6)
        } else if abs(value.translation.width) > 20 {
            // 没切换但有明显拖动，给个轻微反馈
            selectionFeedback.selectionChanged()
        }
        
        // 丝滑弹簧动画
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0)) {
            currentIndex = newIndex
            dragOffset = 0
        }
    }
    
    // MARK: - 底部栏
    
    private var bottomBar: some View {
        HStack {
            if !jots.isEmpty {
                pageIndicator
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
    
    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<min(jots.count, 5), id: \.self) { i in
                Circle()
                    .fill(i == currentIndex ? Color.primary : Color.secondary.opacity(0.3))
                    .frame(width: i == currentIndex ? 8 : 6, height: i == currentIndex ? 8 : 6)
                    .animation(.spring(response: 0.3), value: currentIndex)
            }
            if jots.count > 5 {
                Text("+\(jots.count - 5)")
                    .font(.caption2)
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
    
    private func deleteJot(at index: Int) {
        guard index < jots.count else { return }
        let jot = jots[index]
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            modelContext.delete(jot)
            if currentIndex >= jots.count - 1 {
                currentIndex = max(0, jots.count - 2)
            }
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
