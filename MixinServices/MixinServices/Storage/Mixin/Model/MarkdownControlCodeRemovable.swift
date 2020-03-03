import Foundation
import SwiftyMarkdown

protocol MarkdownControlCodeRemovable {
    
    var content: String { get }
    var isPostContent: Bool { get }
    
}

extension MarkdownControlCodeRemovable {
    
    func makeMarkdownControlCodeRemovedContent() -> String {
        guard isPostContent else {
            return content
        }
        var endIndex = content.endIndex
        var suffix = ""
        for (index, char) in content.enumerated() {
            let didMeetLineBreak = char == "\n"
            let didReachMaxLength = index == 60
            if didMeetLineBreak || didReachMaxLength {
                endIndex = content.index(content.startIndex, offsetBy: index)
                if didReachMaxLength {
                    suffix = "..."
                }
                break
            }
        }
        let fragment = String(content[content.startIndex..<endIndex])
        let md = SwiftyMarkdown(string: fragment)
        return md.attributedString().string + suffix
    }
    
}
