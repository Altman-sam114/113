import SwiftUI
import UIKit

enum AppThemeMode: String, CaseIterable, Identifiable {
    case dark
    case light

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dark:
            return "sun.max.fill"
        case .light:
            return "moon.fill"
        }
    }

    var title: String {
        switch self {
        case .dark:
            return "暗色"
        case .light:
            return "亮色"
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .dark:
            return .dark
        case .light:
            return .light
        }
    }

    var toggled: AppThemeMode {
        self == .dark ? .light : .dark
    }
}

struct AppThemePalette {
    let mode: AppThemeMode

    var isDark: Bool { mode == .dark }
    var primaryText: Color { isDark ? Color(red: 0.91, green: 0.95, blue: 0.97) : Color(red: 0.10, green: 0.16, blue: 0.20) }
    var secondaryText: Color { isDark ? Color(red: 0.65, green: 0.73, blue: 0.79) : Color(red: 0.32, green: 0.40, blue: 0.45) }
    var tertiaryText: Color { secondaryText }
    var inverseText: Color { isDark ? Color(red: 0.03, green: 0.15, blue: 0.15) : .white }
    var accent: Color { isDark ? Color(red: 0.46, green: 0.89, blue: 0.79) : Color(red: 0.02, green: 0.43, blue: 0.39) }
    var secondaryAccent: Color { isDark ? Color(red: 0.56, green: 0.65, blue: 0.98) : Color(red: 0.34, green: 0.39, blue: 0.73) }
    var success: Color { accent }
    var warning: Color { isDark ? Color(red: 0.95, green: 0.76, blue: 0.44) : Color(red: 0.57, green: 0.34, blue: 0.07) }
    var canvas: Color { isDark ? Color(red: 0.039, green: 0.059, blue: 0.078) : Color(red: 0.95, green: 0.97, blue: 0.97) }
    var surface: Color { isDark ? Color(red: 0.071, green: 0.098, blue: 0.125) : .white }
    var recessedSurface: Color { isDark ? Color(red: 0.048, green: 0.074, blue: 0.094) : Color(red: 0.93, green: 0.95, blue: 0.95) }
    var chipSurface: Color { isDark ? Color(red: 0.105, green: 0.14, blue: 0.17) : Color(red: 0.91, green: 0.94, blue: 0.94) }
    var border: Color { isDark ? Color(red: 0.20, green: 0.26, blue: 0.30) : Color(red: 0.78, green: 0.83, blue: 0.84) }
    var subtleBorder: Color { border.opacity(0.55) }
    var grid: Color { accent.opacity(0.12) }

    var backgroundColors: [Color] { [canvas, canvas, recessedSurface] }

}

enum WorkbenchVisualStylePolicy {
    static let controlCornerRadius: CGFloat = 8
    static let panelCornerRadius: CGFloat = 8
    static let iconCornerRadius: CGFloat = 6
    static let compactNavigationSpacing: CGFloat = 4
    static let compactNavigationInset: CGFloat = 4
    static let sidebarNavigationSpacing: CGFloat = 4
    static let sidebarIconSize: CGFloat = 30
    static let sidebarSelectionIndicatorWidth: CGFloat = 3
    static let sidebarSelectionIndicatorVerticalInset: CGFloat = 8
    static let compactSelectionIndicatorWidth: CGFloat = 24
    static let compactSelectionIndicatorHeight: CGFloat = 2
    static let hairlineWidth: CGFloat = 1
    static let panelPadding: CGFloat = 14
    static let panelInnerHighlightWidth: CGFloat = 0.5
    static let panelContactShadowRadius: CGFloat = 1.5
    static let panelContactShadowY: CGFloat = 1
    static let panelAmbientShadowRadius: CGFloat = 8
    static let panelAmbientShadowY: CGFloat = 3
    static let selectedBorderOpacity = 0.34
    static let unselectedIconSurfaceOpacity = 0.06

    static func selectedSurfaceOpacity(isDark: Bool) -> Double {
        isDark ? 0.16 : 0.10
    }

    static func panelTintOpacity(isDark: Bool) -> Double {
        isDark ? 0.36 : 0.58
    }

    static func panelInnerHighlightOpacity(isDark: Bool) -> Double {
        isDark ? 0.18 : 0.48
    }

    static func panelContactShadowOpacity(isDark: Bool) -> Double {
        isDark ? 0.28 : 0.10
    }

    static func panelAmbientShadowOpacity(isDark: Bool) -> Double {
        isDark ? 0.20 : 0.08
    }

    static func sidebarTintOpacity(isDark: Bool) -> Double {
        isDark ? 0.38 : 0.56
    }

    static func usesSelectionIndicator(isSelected: Bool) -> Bool {
        isSelected
    }
}

struct AppBackground: View {
    let theme: AppThemePalette
    var wallpaperData: Data = Data()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                theme.canvas
                if let image = UIImage(data: wallpaperData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .overlay(theme.canvas.opacity(theme.isDark ? 0.86 : 0.90))
                } else {
                    RadialGradient(
                        colors: [theme.accent.opacity(theme.isDark ? 0.065 : 0.045), .clear],
                        center: .topTrailing, startRadius: 0, endRadius: 850
                    )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct WorkbenchPanelModifier: ViewModifier {
    @Environment(\.appTheme) private var theme

    let border: Color?

    func body(content: Content) -> some View {
        content
            .padding(WorkbenchVisualStylePolicy.panelPadding)
            .background {
                ZStack {
                    RoundedRectangle(
                        cornerRadius: WorkbenchVisualStylePolicy.panelCornerRadius,
                        style: .continuous
                    )
                    .fill(theme.surface)
                    RoundedRectangle(
                        cornerRadius: WorkbenchVisualStylePolicy.panelCornerRadius,
                        style: .continuous
                    )
                    .fill(
                        theme.surface.opacity(
                            WorkbenchVisualStylePolicy.panelTintOpacity(isDark: theme.isDark)
                        )
                    )
                }
                .shadow(
                    color: Color.black.opacity(
                        WorkbenchVisualStylePolicy.panelContactShadowOpacity(isDark: theme.isDark)
                    ),
                    radius: WorkbenchVisualStylePolicy.panelContactShadowRadius,
                    y: WorkbenchVisualStylePolicy.panelContactShadowY
                )
                .shadow(
                    color: Color.black.opacity(
                        WorkbenchVisualStylePolicy.panelAmbientShadowOpacity(isDark: theme.isDark)
                    ),
                    radius: WorkbenchVisualStylePolicy.panelAmbientShadowRadius,
                    y: WorkbenchVisualStylePolicy.panelAmbientShadowY
                )
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
            .overlay {
                RoundedRectangle(
                    cornerRadius: WorkbenchVisualStylePolicy.panelCornerRadius,
                    style: .continuous
                )
                .inset(by: WorkbenchVisualStylePolicy.hairlineWidth)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(
                                WorkbenchVisualStylePolicy.panelInnerHighlightOpacity(
                                    isDark: theme.isDark
                                )
                            ),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: WorkbenchVisualStylePolicy.panelInnerHighlightWidth
                )
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
            .overlay {
                RoundedRectangle(
                    cornerRadius: WorkbenchVisualStylePolicy.panelCornerRadius,
                    style: .continuous
                )
                .stroke(
                    border ?? theme.border,
                    lineWidth: WorkbenchVisualStylePolicy.hairlineWidth
                )
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
    }
}

extension View {
    func panelStyle(border: Color? = nil) -> some View {
        modifier(WorkbenchPanelModifier(border: border))
    }

    func primaryActionStyle(isActive: Bool) -> some View {
        self
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(isActive ? .black : Color.primary)
            .padding(.vertical, 11)
            .background(isActive ? Color.cyan : Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isActive ? Color.cyan.opacity(0.6) : Color.primary.opacity(0.12), lineWidth: 1)
            }
            .buttonStyle(.plain)
    }

    func secondaryActionStyle() -> some View {
        self
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Color.primary)
            .padding(.vertical, 11)
            .background(Color.green.opacity(0.16), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.green.opacity(0.32), lineWidth: 1)
            }
            .buttonStyle(.plain)
    }

    func compactUtilityStyle() -> some View {
        self
            .foregroundStyle(Color.primary.opacity(0.86))
            .padding(.vertical, ModelArtifactUtilityTextLayoutPolicy.verticalPadding)
            .background(Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(Color.primary.opacity(0.14), lineWidth: 1)
            }
            .buttonStyle(.plain)
    }
}
