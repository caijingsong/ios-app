import UIKit

class TrailingInfoBackgroundView: UIView {
    
    static let height: CGFloat = 18
    
    convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: 60, height: Self.height))
        backgroundColor = .tagBackground
        clipsToBounds = true
        layer.cornerRadius = 9
    }
    
}
