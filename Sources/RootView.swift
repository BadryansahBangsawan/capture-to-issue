import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: FunTheme.sectionSpacing) {
            if let error = model.bannerError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.callout)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let warning = model.bannerWarning {
                Label(warning, systemImage: "info.circle")
                    .foregroundStyle(.orange)
                    .font(.callout)
                    .textSelection(.enabled)
            }
            if let loadError = model.historyLoadError {
                Label(loadError, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.callout)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let status = model.lastStatus {
                Text(status)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            if !model.hasScreenAccess {
                Label("Screen Recording is required to capture a region.", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
                Text("If the switch is already on, turn it off and on, then Relaunch.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Button("Open Screen Recording Settings") {
                        model.openScreenRecordingSettings()
                    }
                    Button("Relaunch") {
                        model.relaunch()
                    }
                }
            }

            if model.history.isEmpty {
                if !model.hasScreenAccess || model.isCapturing {
                    Button("Capture region") {
                        model.beginCapture()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isCapturing || !model.hasScreenAccess)
                }

                ExtraEmptyState(
                    title: "No captures",
                    detail: "Capture a region to file a GitHub issue.",
                    actionTitle: model.hasScreenAccess ? "Capture region" : "Open Screen Recording Settings",
                    action: {
                        if model.hasScreenAccess {
                            model.beginCapture()
                        } else {
                            model.openScreenRecordingSettings()
                        }
                    }
                )
            } else {
                Button("Capture region") {
                    model.beginCapture()
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isCapturing || !model.hasScreenAccess)

                VStack(alignment: .leading, spacing: FunTheme.innerSpacing) {
                    Text("Recent")
                        .font(.headline)
                    ForEach(model.history) { item in
                        Text(item.title)
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                            .extraRowSurface()
                    }
                }
            }

            ExtraSettingsFooter()
        }
        .animation(reduceMotion ? nil : FunTheme.spring, value: model.history.count)
        .animation(reduceMotion ? nil : FunTheme.spring, value: model.hasScreenAccess)
        .funPanel()
        .task {
            await model.refreshPermission()
        }
    }
}
