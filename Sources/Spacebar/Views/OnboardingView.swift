import AppKit
import SpacebarCore
import SwiftUI

/// Shown once, before the first scan: what Spacebar does, Full Disk Access, and how it keeps you safe.
struct OnboardingView: View {
    @EnvironmentObject private var model: AppModel
    /// Persisted so the walkthrough resumes on the same page after "Quit & Reopen".
    @AppStorage(Preferences.onboardingPage) private var page = 0
    let finish: () -> Void

    private let pageCount = 3

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch page {
                case 0: welcome
                case 1: fullDiskAccess
                default: safety
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(32)

            Divider()
            HStack {
                HStack(spacing: 6) {
                    ForEach(0..<pageCount, id: \.self) { index in
                        Circle()
                            .fill(index == page ? Color.accentColor : Color.secondary.opacity(0.3))
                            .frame(width: 7, height: 7)
                    }
                }
                .accessibilityLabel("Step \(page + 1) of \(pageCount)")
                Spacer()
                if page > 0 {
                    Button("Back") { page -= 1 }
                }
                if page < pageCount - 1 {
                    Button(page == 1 && model.fullDiskAccess != true ? "Skip for Now" : "Continue") { page += 1 }
                        .keyboardShortcut(.defaultAction)
                } else {
                    Button("Start Scan") { finish() }
                        .keyboardShortcut(.defaultAction)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
        }
        .frame(width: 580, height: 480)
        .onAppear { model.refreshSystem() }
    }

    // MARK: Pages

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome to Spacebar").font(.largeTitle.weight(.semibold))
                    Text("See what's using your disk, and free space safely.").foregroundStyle(.secondary)
                }
            }
            VStack(alignment: .leading, spacing: 12) {
                point("chart.bar.xaxis", "What's using space",
                      "A measured breakdown of your disk, and Space Explorer to drill into any folder.")
                point("sparkles", "Cleanup you can trust",
                      "Caches, logs and build data apps rebuild, plus forgotten downloads, unused apps, old simulators and leftovers.")
                point("menubar.rectangle", "Always at hand",
                      "Available space in the menu bar, and an alert before your disk fills up.")
                point("hand.raised", "Private",
                      "Everything happens on your Mac. No account, no analytics. The only network use is checking for updates.")
            }
        }
    }

    private var fullDiskAccess: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Full Disk Access").font(.title.weight(.semibold))
            Text("macOS hides some folders from apps unless you allow it. With Full Disk Access, Spacebar can also measure and clean your Trash, Mail attachments, iPhone backups and app containers, and it won't trigger separate permission prompts for Desktop, Documents and Downloads.")
                .fixedSize(horizontal: false, vertical: true)
            Text("Spacebar only reads file sizes and dates. It never opens your documents or sends anything anywhere.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                Image(systemName: model.fullDiskAccess == true ? "checkmark.circle.fill" : "circle.dashed")
                    .font(.title2)
                    .foregroundStyle(model.fullDiskAccess == true ? Color.green : Color.secondary)
                Text(model.fullDiskAccess == true ? "Full Disk Access is on" : "Not turned on yet")
                    .font(.headline)
            }
            .padding(.top, 4)

            if model.fullDiskAccess != true {
                VStack(alignment: .leading, spacing: 6) {
                    Text("1. Click Open System Settings.")
                    Text("2. Turn on Spacebar. If it isn't listed, click + and choose Spacebar in Applications.")
                    Text("3. Click Quit & Reopen, and Spacebar continues right here.")
                }
                .font(.callout)
                .foregroundStyle(.secondary)
                HStack {
                    Button("Open System Settings") {
                        FullDiskAccess.openSettings()
                        model.watchForFullDiskAccess()
                    }
                    Button("Quit & Reopen") { model.relaunch() }
                }
            }
        }
    }

    private var safety: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("You stay in control").font(.title.weight(.semibold))
            VStack(alignment: .leading, spacing: 12) {
                point("checkmark.circle", "Only safe items are suggested",
                      "Caches nobody has used for a month, logs, and build data are preselected. Your files, apps and anything else are listed for you to review, never preselected.")
                point("arrow.uturn.backward.circle", "Put Back",
                      "Items that might matter go to the Trash. Put Back (⌥⌘Z) returns everything from your last clean.")
                point("lock.shield", "Protected locations",
                      "Your documents' folders, passwords, Mail, iCloud Drive, security keys and the apps you're running are never removed.")
                point("list.bullet.rectangle", "Everything is logged",
                      "Each removal is recorded in ~/Library/Logs/Spacebar/operations.log.")
            }
            Toggle(isOn: $model.dryRun) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Dry run")
                    Text("Practice first: cleaning only shows what it would remove.").font(.caption).foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.switch)
        }
    }

    private func point(_ icon: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(text).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
