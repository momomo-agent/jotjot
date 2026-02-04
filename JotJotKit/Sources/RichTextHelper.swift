import Foundation
#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
public typealias PlatformFont = UIFont
public typealias PlatformColor = UIColor
#elseif canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
public typealias PlatformFont = NSFont
public typealias PlatformColor = NSColor
#endif

// MARK: - 富文本工具
public enum RichTextHelper {
    
    /// 默认字体
    public static var defaultFont: PlatformFont {
        #if canImport(UIKit)
        return .systemFont(ofSize: 17)
        #else
        return .systemFont(ofSize: 14)
        #endif
    }
    
    /// 默认文本颜色
    public static var defaultTextColor: PlatformColor {
        #if canImport(UIKit)
        return .label
        #else
        return .textColor
        #endif
    }
    
    /// 默认段落样式
    public static var defaultParagraphStyle: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 6
        return style
    }
    
    /// 默认属性
    public static var defaultAttributes: [NSAttributedString.Key: Any] {
        [
            .font: defaultFont,
            .foregroundColor: defaultTextColor,
            .paragraphStyle: defaultParagraphStyle
        ]
    }
}
