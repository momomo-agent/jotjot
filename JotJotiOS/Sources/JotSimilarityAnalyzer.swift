import Foundation

/// 笔记相似度分析器
struct JotSimilarityAnalyzer {
    
    struct SimilarPair {
        let jot1: Jot
        let jot2: Jot
        let score: Double
        let reason: String
    }
    
    /// 分析笔记列表，找出相似的笔记对
    static func findSimilarPairs(in jots: [Jot], threshold: Double = 0.3) -> [SimilarPair] {
        var pairs: [SimilarPair] = []
        
        for i in 0..<jots.count {
            for j in (i+1)..<jots.count {
                let jot1 = jots[i]
                let jot2 = jots[j]
                
                if let pair = analyzePair(jot1, jot2, threshold: threshold) {
                    pairs.append(pair)
                }
            }
        }
        
        return pairs.sorted { $0.score > $1.score }
    }
    
    private static func analyzePair(_ jot1: Jot, _ jot2: Jot, threshold: Double) -> SimilarPair? {
        let text1 = jot1.content.lowercased()
        let text2 = jot2.content.lowercased()
        
        // 跳过空笔记
        guard !text1.isEmpty && !text2.isEmpty else { return nil }
        
        var score: Double = 0
        var reasons: [String] = []
        
        // 1. 关键词重叠
        let keywords1 = extractKeywords(from: text1)
        let keywords2 = extractKeywords(from: text2)
        let overlap = keywords1.intersection(keywords2)
        
        if !overlap.isEmpty {
            let overlapScore = Double(overlap.count) / Double(max(keywords1.count, keywords2.count))
            score += overlapScore * 0.4
            if overlapScore > 0.3 {
                reasons.append("关键词相似")
            }
        }
        
        // 2. 首行相似（可能是同一主题）
        let firstLine1 = text1.components(separatedBy: "\n").first ?? ""
        let firstLine2 = text2.components(separatedBy: "\n").first ?? ""
        
        if !firstLine1.isEmpty && !firstLine2.isEmpty {
            let firstLineScore = stringSimilarity(firstLine1, firstLine2)
            score += firstLineScore * 0.3
            if firstLineScore > 0.5 {
                reasons.append("标题相似")
            }
        }
        
        // 3. 时间接近（1小时内创建）
        let timeDiff = abs(jot1.createdAt.timeIntervalSince(jot2.createdAt))
        if timeDiff < 3600 {
            score += 0.2
            reasons.append("创建时间接近")
        }
        
        // 4. 长度相似
        let lenRatio = Double(min(text1.count, text2.count)) / Double(max(text1.count, text2.count))
        score += lenRatio * 0.1
        
        guard score >= threshold else { return nil }
        
        return SimilarPair(
            jot1: jot1,
            jot2: jot2,
            score: score,
            reason: reasons.isEmpty ? "内容相关" : reasons.joined(separator: "、")
        )
    }
    
    // MARK: - 辅助函数
    
    private static func extractKeywords(from text: String) -> Set<String> {
        // 简单分词，过滤停用词
        let stopWords: Set<String> = ["的", "是", "在", "了", "和", "与", "或", "a", "the", "is", "are", "to", "and", "or"]
        
        let words = text.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 1 && !stopWords.contains($0) }
        
        return Set(words)
    }
    
    private static func stringSimilarity(_ s1: String, _ s2: String) -> Double {
        let set1 = Set(s1)
        let set2 = Set(s2)
        let intersection = set1.intersection(set2)
        let union = set1.union(set2)
        return union.isEmpty ? 0 : Double(intersection.count) / Double(union.count)
    }
}
