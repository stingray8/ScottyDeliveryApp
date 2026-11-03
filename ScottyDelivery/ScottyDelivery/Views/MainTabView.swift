import SwiftUI

public struct MainTabView: View {
    public init() {}

    public var body: some View {
        ScottyDeliveryFlowView()
    }
}

#Preview("iPhone 17", traits: .fixedLayout(width: 402, height: 874)) {
    MainTabView()
}
