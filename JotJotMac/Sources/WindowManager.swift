import SwiftUI
import AppKit

@MainActor
final class WindowManager: ObservableObject {
    static let shared = WindowManager()
    
    @Published var isVisible = true
    private var mainWindow: NSWindow?
    
    func setup(_ window: NSWindow?) {
        self.mainWindow = window
        configureWindow(window)
    }
    
    private func configureWindow(_ window: NSWindow?) {
        guard let window = window else { return }
        
        // 窗口样式
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }
    
    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }
    
    func show() {
        guard let window = mainWindow ?? NSApp.windows.first else { return }
        
        // 准备动画 - 从稍微缩小和透明开始
        window.alphaValue = 0
        let originalFrame = window.frame
        let scaledFrame = NSRect(
            x: originalFrame.midX - originalFrame.width * 0.48,
            y: originalFrame.midY - originalFrame.height * 0.48,
            width: originalFrame.width * 0.96,
            height: originalFrame.height * 0.96
        )
        window.setFrame(scaledFrame, display: false)
        
        // 激活并显示
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.center()
        
        // 弹出动画
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
            window.animator().setFrame(originalFrame, display: true)
        }
        
        isVisible = true
    }
    
    func hide() {
        guard let window = mainWindow ?? NSApp.windows.first else { return }
        
        let originalFrame = window.frame
        
        // 收起动画 - 缩小并淡出
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
            
            let scaledFrame = NSRect(
                x: originalFrame.midX - originalFrame.width * 0.48,
                y: originalFrame.midY - originalFrame.height * 0.48,
                width: originalFrame.width * 0.96,
                height: originalFrame.height * 0.96
            )
            window.animator().setFrame(scaledFrame, display: true)
        }, completionHandler: {
            window.orderOut(nil)
            window.setFrame(originalFrame, display: false)
            window.alphaValue = 1
        })
        
        isVisible = false
    }
}
