import SwiftUI

enum GgotgalpiTheme {
    // #F8F2E8에 가까운 따뜻한 화이트: 흰색의 인상을 지키되 베이지 기운을 분명히 남깁니다.
    static let paper = Color(red: 0.973, green: 0.949, blue: 0.910)
    static let paperDeep = Color(red: 0.949, green: 0.922, blue: 0.867)
    static let ink = Color(red: 0.18, green: 0.18, blue: 0.17)
    static let secondaryInk = Color(red: 0.43, green: 0.41, blue: 0.37)
    static let line = Color(red: 0.84, green: 0.82, blue: 0.77)
    // 월간 달력의 가로·세로 격자에만 쓰는 은은한 웜 그레이입니다.
    static let calendarGridLine = Color(red: 0.875, green: 0.847, blue: 0.796)
    static let accent = Color(red: 0.46, green: 0.43, blue: 0.36)

    enum Spacing {
        static let compact: CGFloat = 8
        static let control: CGFloat = 12
        static let content: CGFloat = 16
        static let screen: CGFloat = 20
        static let section: CGFloat = 24
        static let largeSection: CGFloat = 32
    }
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
                .font(.headline)
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

struct BookColorMark: View {
    let title: String
    let color: Color
    var size: CGFloat = 48

    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(color)
            .frame(width: size, height: size)
            .overlay {
                Text(String(title.prefix(1)))
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.92))
            }
            .accessibilityHidden(true)
    }
}

struct DividerLine: View {
    var body: some View {
        Rectangle()
            .fill(GgotgalpiTheme.line)
            .frame(height: 0.7)
    }
}

struct ReadingEmptyState: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: GgotgalpiTheme.Spacing.compact) {
            Image(systemName: "text.book.closed")
                .font(.title2)
                .foregroundStyle(GgotgalpiTheme.accent)

            Text(title)
                .font(.headline)
                .foregroundStyle(GgotgalpiTheme.ink)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(GgotgalpiTheme.secondaryInk)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, GgotgalpiTheme.Spacing.largeSection)
        .padding(.horizontal, GgotgalpiTheme.Spacing.content)
    }
}

struct DesignSystemShowcase_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: GgotgalpiTheme.Spacing.section) {
                SectionLabel(title: "공통 요소", actionTitle: "텍스트 액션") {}

                DatePicker(
                    "감상 날짜 선택",
                    selection: .constant(Date()),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "ko_KR"))

                HStack(spacing: GgotgalpiTheme.Spacing.content) {
                    BookColorMark(
                        title: "어린 왕자",
                        color: Color(red: 0.55, green: 0.65, blue: 0.61),
                        size: 48
                    )

                    ReadingEmptyState(
                        title: "감상 없음",
                        message: "선택한 날의 빈 상태입니다."
                    )
                }
            }
            .padding(GgotgalpiTheme.Spacing.screen)
        }
        .paperBackground()
        .previewDisplayName("디자인 시스템")
    }
}
