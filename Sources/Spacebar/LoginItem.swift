import ServiceManagement

/// "Open at login", so automatic cleaning and low-disk alerts keep working.
enum LoginItem {
    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    static func set(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            // Needs approval in System Settings › General › Login Items.
            SMAppService.openSystemSettingsLoginItems()
        }
    }
}
