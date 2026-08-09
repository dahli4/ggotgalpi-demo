import SwiftUI

enum GgotgalpiTheme {
    static let paper = Color(red: 0.975, green: 0.964, blue: 0.936)
    static let paperDeep = Color(red: 0.949, green: 0.932, blue: 0.895)
    static let ink = Color(red: 0.18, green: 0.18, blue: 0.17)
    static let secondaryInk = Color(red: 0.43, green: 0.41, blue: 0.37)
    static let line = Color(red: 0.82, green: 0.79, blue: 0.72)
    static let calendarLine = Color(red: 0.22, green: 0.22, blue: 0.20)
    static let accent = Color(red: 0.46, green: 0.43, blue: 0.36)
    static let softAccent = Color(red: 0.86, green: 0.82, blue: 0.74)
}

struct PaperBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(GgotgalpiTheme.paper.ignoresSafeArea())
            .tint(GgotgalpiTheme.accent)
    }
}

extension View {
    func paperBackground() -> some View {
        modifier(PaperBackground())
    }
}

struct SectionLabel: View {
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(.headline, design: .serif))
                .foregroundStyle(GgotgalpiTheme.ink)

            Spacer()

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.caption)
                    .foregroundStyle(GgotgalpiTheme.secondaryInk)
            }
        }
    }
}

struct CoverPlaceholder: View {
    let title: String
    let color: Color
    var size: CGSize = CGSize(width: 92, height: 132)

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 6)
                .fill(color.gradient)

            VStack(alignment: .leading, spacing: 5) {
                Text("꽃갈피")
                    .font(.system(size: 8, weight: .medium, design: .serif))
                    .opacity(0.72)

                Text(title)
                    .font(.system(size: max(10, size.width / 8), weight: .semibold, design: .serif))
                    .lineLimit(3)
                    .minimumScaleFactor(0.65)
            }
            .foregroundStyle(.white.opacity(0.92))
            .padding(size.width * 0.12)
        }
        .frame(width: size.width, height: size.height)
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(GgotgalpiTheme.ink.opacity(0.12), lineWidth: 0.8)
        }
        .shadow(color: .black.opacity(0.08), radius: 5, y: 3)
    }
}

struct DividerLine: View {
    var body: some View {
        Rectangle()
            .fill(GgotgalpiTheme.line)
            .frame(height: 0.7)
    }
}
