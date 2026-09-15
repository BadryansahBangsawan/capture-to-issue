import SwiftUI

enum FunTheme {
    static let spring = Animation.spring(response: 0.35, dampingFraction: 1.0)
    static let panelWidth: CGFloat = 360
}

extension View {
    func funPanel() -> some View {
        self
            .frame(width: FunTheme.panelWidth, alignment: .leading)
            .font(.system(.body))
            .padding(12)
    }
}
