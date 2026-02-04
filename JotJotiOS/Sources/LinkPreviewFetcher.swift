import Foundation

/// 社交媒体链接提取器
actor LinkPreviewFetcher {
    
    struct LinkPreview {
        let url: URL
        let title: String?
        let description: String?
        let imageURL: URL?
        let siteName: String?
    }
    
    /// 从 URL 提取预览信息
    func fetchPreview(for url: URL) async -> LinkPreview? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else { return nil }
            
            return LinkPreview(
                url: url,
                title: extractMetaContent(from: html, property: "og:title") 
                    ?? extractMetaContent(from: html, name: "title")
                    ?? extractTitle(from: html),
                description: extractMetaContent(from: html, property: "og:description")
                    ?? extractMetaContent(from: html, name: "description"),
                imageURL: extractMetaContent(from: html, property: "og:image")
                    .flatMap { URL(string: $0) },
                siteName: extractMetaContent(from: html, property: "og:site_name")
                    ?? detectSiteName(from: url)
            )
        } catch {
            return nil
        }
    }
    
    // MARK: - HTML 解析
    
    private func extractMetaContent(from html: String, property: String) -> String? {
        // <meta property="og:title" content="...">
        let pattern = #"<meta[^>]+property=["']\#(property)["'][^>]+content=["']([^"']+)["']"#
        return extractRegex(pattern: pattern, from: html)
            ?? extractRegex(pattern: #"<meta[^>]+content=["']([^"']+)["'][^>]+property=["']\#(property)["']"#, from: html)
    }
    
    private func extractMetaContent(from html: String, name: String) -> String? {
        // <meta name="description" content="...">
        let pattern = #"<meta[^>]+name=["']\#(name)["'][^>]+content=["']([^"']+)["']"#
        return extractRegex(pattern: pattern, from: html)
    }
    
    private func extractTitle(from html: String) -> String? {
        // <title>...</title>
        let pattern = #"<title[^>]*>([^<]+)</title>"#
        return extractRegex(pattern: pattern, from: html)
    }
    
    private func extractRegex(pattern: String, from html: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: match.numberOfRanges > 1 ? 1 : 0), in: html) else {
            return nil
        }
        return String(html[range]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func detectSiteName(from url: URL) -> String? {
        guard let host = url.host?.lowercased() else { return nil }
        
        if host.contains("twitter.com") || host.contains("x.com") { return "Twitter" }
        if host.contains("weibo.com") || host.contains("weibo.cn") { return "微博" }
        if host.contains("xiaohongshu.com") { return "小红书" }
        if host.contains("bilibili.com") { return "哔哩哔哩" }
        if host.contains("zhihu.com") { return "知乎" }
        if host.contains("douyin.com") { return "抖音" }
        if host.contains("youtube.com") || host.contains("youtu.be") { return "YouTube" }
        if host.contains("github.com") { return "GitHub" }
        
        return nil
    }
}
