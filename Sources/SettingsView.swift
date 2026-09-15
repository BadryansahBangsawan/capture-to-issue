import AppKit
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var loginEnabled = false
    @State private var loginStatus = ""

    var body: some View {
        Form {
            TextField("Default repo (owner/repo)", text: $model.defaultRepo)
            Toggle("Open at Login", isOn: $loginEnabled)
                .onChange(of: loginEnabled) { _, on in
                    do {
                        if on {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                        loginStatus = ""
                    } catch {
                        loginStatus = error.localizedDescription
                        loginEnabled = SMAppService.mainApp.status == .enabled
                    }
                }
            if !loginStatus.isEmpty {
                Text(loginStatus)
                    .foregroundStyle(.red)
                    .font(.callout)
                    .textSelection(.enabled)
            }
            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
        .frame(width: FunTheme.panelWidth)
        .padding(12)
        .onAppear {
            loginEnabled = SMAppService.mainApp.status == .enabled
        }
    }
}
