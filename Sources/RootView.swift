import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let error = model.bannerError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.callout)
                    .textSelection(.enabled)
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
                Button("Open Screen Recording Settings") {
                    model.openScreenRecordingSettings()
                }
            }

            if model.history.isEmpty {
                Text("Capture a region to file an issue.")
                    .foregroundStyle(.secondary)
                Button("Capture region") {
                    model.beginCapture()
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isCapturing || !model.hasScreenAccess)
            } else {
                Button("Capture region") {
                    model.beginCapture()
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isCapturing || !model.hasScreenAccess)

                Text("Recent")
                    .font(.headline)
                ForEach(model.history) { item in
                    Text(item.title)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()
            SettingsLink {
                Text("Settings…")
            }
        }
        .funPanel()
        .background(.regularMaterial)
        .animation(reduceMotion ? nil : FunTheme.spring, value: model.history.count)
        .animation(reduceMotion ? nil : FunTheme.spring, value: model.hasScreenAccess)
        .task {
            await model.refreshPermission()
        }
    }
}
