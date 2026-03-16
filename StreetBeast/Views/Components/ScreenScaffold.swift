import SwiftUI

struct ScreenScaffold<Header: View, Content: View>: View {
    var showsIndicators: Bool = false
    var contentTopPadding: CGFloat = 120
    var horizontalPadding: CGFloat = 0
    var bottomPadding: CGFloat = 140

    @ViewBuilder let header: () -> Header
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack(alignment: .top) {
            StreetBeastBackground()

            ScrollView(showsIndicators: showsIndicators) {
                content()
                    .padding(.top, contentTopPadding)
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, bottomPadding)
            }

            header()
        }
    }
}

#Preview {
    ScreenScaffold(
        contentTopPadding: 120,
        horizontalPadding: 24,
        bottomPadding: 120,
        header: { CustomNavigationBar(title: "Preview") },
        content: {
            VStack(spacing: 24) {
                Text("Content")
                Text("More content")
            }
        }
    )
}
