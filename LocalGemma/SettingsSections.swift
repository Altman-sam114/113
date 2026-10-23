import PhotosUI
import SwiftUI

enum SettingsSectionsLayoutMode: Equatable {
    case stacked
    case columns
}

struct SettingsSectionsLayoutPlan: Equatable {
    let mode: SettingsSectionsLayoutMode
    let contentWidth: CGFloat
    let preferenceWidth: CGFloat
    let runtimeWidth: CGFloat
}

enum SettingsSectionsLayoutPolicy {
    static let preferenceColumnWidth: CGFloat = 320
    static let columnSpacing: CGFloat = 24
    static let maximumReadingWidth: CGFloat = 760
    static let minimumRuntimeColumnWidth = OptimizationToggleGridLayoutPolicy.twoColumnThreshold
        + WorkbenchVisualStylePolicy.panelPadding * 2
    static let columnsThreshold = preferenceColumnWidth + columnSpacing + minimumRuntimeColumnWidth
    static let maximumContentWidth = preferenceColumnWidth + columnSpacing + maximumReadingWidth

    static func resolve(contentWidth: CGFloat, dynamicTypeSize: DynamicTypeSize) -> SettingsSectionsLayoutPlan {
        let width = contentWidth.isFinite && contentWidth > 0 ? contentWidth : 0
        let usesColumns = width >= columnsThreshold && dynamicTypeSize < .xxxLarge
        let resolvedWidth = min(width, usesColumns ? maximumContentWidth : maximumReadingWidth)
        return SettingsSectionsLayoutPlan(
            mode: usesColumns ? .columns : .stacked,
            contentWidth: resolvedWidth,
            preferenceWidth: usesColumns ? preferenceColumnWidth : resolvedWidth,
            runtimeWidth: usesColumns ? resolvedWidth - preferenceColumnWidth - columnSpacing : resolvedWidth
        )
    }
}

enum SettingsWorkspaceLayoutPolicy {
    static let horizontalPadding: CGFloat = 18
    static let minimumReadableWidth: CGFloat = 320
    static let maximumContentWidth = SettingsSectionsLayoutPolicy.maximumContentWidth

    static func resolve(
        forContainerWidth containerWidth: CGFloat,
        dynamicTypeSize: DynamicTypeSize
    ) -> SettingsSectionsLayoutPlan {
        let width = containerWidth.isFinite && containerWidth > 0
            ? max(containerWidth - horizontalPadding * 2, 0)
            : minimumReadableWidth
        return SettingsSectionsLayoutPolicy.resolve(contentWidth: width, dynamicTypeSize: dynamicTypeSize)
    }

    static func contentWidth(forContainerWidth containerWidth: CGFloat) -> CGFloat {
        resolve(forContainerWidth: containerWidth, dynamicTypeSize: .large).contentWidth
    }
}

struct SettingsSectionsShell<Preferences: View, Runtime: View>: View {
    let plan: SettingsSectionsLayoutPlan
    let preferences: Preferences
    let runtime: Runtime

    init(
        plan: SettingsSectionsLayoutPlan,
        @ViewBuilder preferences: () -> Preferences,
        @ViewBuilder runtime: () -> Runtime
    ) {
        self.plan = plan
        self.preferences = preferences()
        self.runtime = runtime()
    }

    var body: some View {
        let layout = plan.mode == .columns
            ? AnyLayout(HStackLayout(alignment: .top, spacing: SettingsSectionsLayoutPolicy.columnSpacing))
            : AnyLayout(VStackLayout(alignment: .leading, spacing: 28))

        // Keep both sections in the same slots when the window or text size changes.
        layout {
            preferences
                .frame(width: plan.preferenceWidth, alignment: .topLeading)
            runtime
                .frame(width: plan.runtimeWidth, alignment: .topLeading)
        }
        .frame(width: plan.contentWidth, alignment: .topLeading)
    }
}

struct SettingsAppearanceSection: View {
    @Environment(\.appTheme) private var theme

    let themeMode: AppThemeMode
    let wallpaperData: Data
    @Binding var selectedItem: PhotosPickerItem?
    let isImporting: Bool
    let availableWidth: CGFloat
    let showsPreview: Bool
    let toggleTheme: () -> Void
    let clearWallpaper: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSectionHeading(eyebrow: "01 / PERSONALIZATION", title: "外观与背景")
            if showsPreview {
                SettingsAppearancePreview(wallpaperData: wallpaperData)
            }
            ThemePreferencePanel(themeMode: themeMode, toggleTheme: toggleTheme)
            WallpaperPreferencePanel(
                wallpaperData: wallpaperData,
                selectedItem: $selectedItem,
                isImporting: isImporting,
                panelContentWidth: SettingsPreferenceRowLayoutPolicy.panelContentWidth(forPanelWidth: availableWidth),
                clearWallpaper: clearWallpaper
            )
            Label {
                Text("相册图片仅在本机压缩保存。恢复系统背景不会修改原始照片。")
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "lock.shield")
                    .foregroundStyle(theme.accent)
            }
            .font(.caption)
            .foregroundStyle(theme.secondaryText)
            .accessibilityElement(children: .combine)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct SettingsRuntimeSection: View {
    @EnvironmentObject private var optimizer: DeviceOptimizer
    @Environment(\.appTheme) private var theme

    let availableWidth: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingsSectionHeading(
                eyebrow: "02 / APPLE SILICON", title: "芯片运行计划",
                subtitle: "Apple Silicon 运行计划与模拟预算，非实时设备性能测量。"
            )
            ChipReadinessCard(
                progress: optimizer.deploymentReadiness,
                thermalState: optimizer.thermalState,
                privacyGuardEnabled: optimizer.isOfflinePrivacyGuardEnabled,
                panelContentWidth: ChipReadinessLayoutPolicy.panelContentWidth(forPanelWidth: availableWidth)
            )
            OptimizerMetricGrid(metrics: optimizer.metrics, availableWidth: availableWidth)
            OptimizationToggleGrid(
                items: optimizer.switches, availableWidth: availableWidth, border: theme.border,
                toggle: { optimizer.toggle($0) }
            )
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct SettingsSectionHeading: View {
    @Environment(\.appTheme) private var theme
    let eyebrow: String
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(eyebrow)
                .font(.caption2.monospaced().weight(.medium))
                .tracking(0.8)
                .foregroundStyle(theme.accent)
                .fixedSize(horizontal: false, vertical: true)
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(theme.primaryText)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct SettingsAppearancePreview: View {
    @Environment(\.appTheme) private var theme
    let wallpaperData: Data

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 5).fill(theme.accent).frame(width: 20, height: 20)
                ForEach(0..<3) { index in
                    Capsule().fill(index == 0 ? theme.accent.opacity(0.25) : theme.border)
                        .frame(width: 38, height: 5)
                }
                Spacer(minLength: 0)
            }
            .padding(10)
            .background(theme.recessedSurface, in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 10) {
                Capsule().fill(theme.primaryText.opacity(0.6)).frame(width: 78, height: 6)
                Capsule().fill(theme.secondaryText.opacity(0.25)).frame(height: 4)
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4).fill(theme.surface)
                    RoundedRectangle(cornerRadius: 4).fill(theme.surface)
                }
                .frame(height: 25)
                Spacer(minLength: 0)
                RoundedRectangle(cornerRadius: 8).fill(theme.surface).frame(height: 24)
            }
            .padding(.vertical, 10)
            .padding(.trailing, 10)
        }
        .padding(12)
        .frame(height: 148)
        .background(AppBackground(theme: theme, wallpaperData: wallpaperData))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay { RoundedRectangle(cornerRadius: 12).stroke(theme.border, lineWidth: 1) }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
