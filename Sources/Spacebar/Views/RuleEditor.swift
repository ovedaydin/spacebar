import AppKit
import SpacebarCore
import SwiftUI

/// Creates or edits a cleanup rule, with a live preview of what it matches now.
struct RuleEditor: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State var rule: CleanupRule
    let isNew: Bool
    @State private var patterns: String = ""
    @State private var preview: (count: Int, bytes: Int64)?
    @State private var confirmDelete = false

    private static let ages = [1, 7, 14, 30, 60, 90, 180, 365]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(isNew ? "New Rule" : "Edit Rule").font(.title2.weight(.semibold))
                Spacer()
                if isNew {
                    Menu("Start From") {
                        ForEach(CleanupRule.presets, id: \.name) { preset in
                            Button(preset.name) {
                                rule = CleanupRule(name: preset.name, folder: preset.folder, patterns: preset.patterns,
                                                   olderThanDays: preset.olderThanDays, depth: preset.depth)
                                patterns = preset.patterns.joined(separator: ", ")
                            }
                        }
                    }
                    .fixedSize()
                }
            }

            Form {
                TextField("Name", text: $rule.name)
                LabeledContent("Folder") {
                    HStack {
                        Text(rule.folder).lineLimit(1).truncationMode(.middle)
                        Spacer()
                        Button("Choose…") { chooseFolder() }
                    }
                }
                TextField("Names to match", text: $patterns, prompt: Text("*.dmg, *.zip"))
                    .help("Separate with commas. * matches any text, ? one character. Case doesn't matter.")
                Picker("Unchanged for", selection: $rule.olderThanDays) {
                    ForEach(Self.ages, id: \.self) { days in Text(ageLabel(days)).tag(days) }
                }
                Picker("Look in", selection: $rule.depth) {
                    Text("This folder only").tag(1)
                    Text("Subfolders, 2 levels").tag(2)
                    Text("Subfolders, 3 levels").tag(3)
                    Text("Subfolders, 5 levels").tag(5)
                }
                Toggle("Include in automatic cleaning", isOn: $rule.automatic)
                    .help("The weekly automatic clean (Settings → Automatic) moves matches to the Trash.")
            }
            .formStyle(.grouped)

            Group {
                if let problem = rule.problem {
                    Label(problem, systemImage: "exclamationmark.triangle").foregroundStyle(.orange)
                } else if let preview {
                    Label(preview.count == 0 ? String(localized: "Nothing matches right now.")
                              : String(localized: "Matches \(preview.count) items (\(ByteFormat.string(preview.bytes))) right now. You review them before anything is removed."),
                          systemImage: "magnifyingglass")
                        .foregroundStyle(.secondary)
                } else {
                    Label("Looking…", systemImage: "magnifyingglass").foregroundStyle(.secondary)
                }
            }
            .font(.callout)

            HStack {
                if !isNew {
                    Button("Delete Rule", role: .destructive) { confirmDelete = true }
                }
                Spacer()
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Button(isNew ? "Add Rule" : "Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(rule.problem != nil)
            }
        }
        .padding(20)
        .frame(width: 520)
        .onAppear { patterns = rule.patterns.joined(separator: ", ") }
        .onChange(of: patterns) { text in
            rule.patterns = text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        }
        // Re-run the preview shortly after edits stop.
        .task(id: rule) {
            preview = nil
            guard rule.problem == nil else { return }
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            let rule = rule
            // Small and someone's waiting on it: not queued behind a full scan.
            let result = await Task.detached(priority: .userInitiated) { rule.preview(engine: BulkScanner()) }.value
            if !Task.isCancelled { preview = result }
        }
        .confirmationDialog("Delete “\(rule.name)”?", isPresented: $confirmDelete) {
            Button("Delete Rule", role: .destructive) {
                model.rules.removeAll { $0.id == rule.id }
                dismiss()
            }
        } message: {
            Text("Files it found aren't touched.")
        }
    }

    private func save() {
        if let index = model.rules.firstIndex(where: { $0.id == rule.id }) {
            model.rules[index] = rule
        } else {
            model.rules.append(rule)
        }
        dismiss()
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.directoryURL = rule.folderURL
        panel.prompt = String(localized: "Choose")
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let home = NSHomeDirectory()
        rule.folder = url.path.hasPrefix(home + "/") ? "~" + url.path.dropFirst(home.count) : url.path
    }

    private func ageLabel(_ days: Int) -> String {
        switch days {
        case 1: return String(localized: "1 day")
        case 7: return String(localized: "1 week")
        case 14: return String(localized: "2 weeks")
        case 30: return String(localized: "1 month")
        case 60: return String(localized: "2 months")
        case 90: return String(localized: "3 months")
        case 180: return String(localized: "6 months")
        default: return String(localized: "1 year")
        }
    }
}
