import SpacebarCore
import SwiftUI

extension StorageSegment {
    /// Slices whose parts explain themselves (macOS, System Data) open a details list.
    var hasDetails: Bool { parts.contains { $0.note != nil } }
}

extension StorageSegment.Part.Verdict {
    var label: LocalizedStringKey {
        switch self {
        case .managed: return "Managed by macOS"
        case .clearedOnRestart: return "Cleared on restart"
        case .review: return "Worth a look"
        case .removable: return "Can be removed"
        }
    }

    var color: Color {
        switch self {
        case .managed, .clearedOnRestart: return .secondary
        case .review: return .orange
        case .removable: return .green
        }
    }
}

/// What's in macOS or System Data, part by part: what it is, whether it's safe to remove,
/// and a button for the parts Spacebar can do something about.
struct SegmentDetailsView: View {
    let segment: StorageSegment
    let perform: (StorageSegment.Part.Action) -> Void
    let exploreAll: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                RoundedRectangle(cornerRadius: 3).fill(segment.kind.color).frame(width: 12, height: 12)
                Text(segment.name).font(.title2.weight(.semibold))
                Spacer()
                Text(ByteFormat.string(segment.bytes)).font(.title2).monospacedDigit().foregroundStyle(.secondary)
            }
            Text(segment.explanation).foregroundStyle(.secondary).padding(.top, 4)
                .fixedSize(horizontal: false, vertical: true)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(segment.parts.enumerated()), id: \.offset) { index, part in
                        if index > 0 { Divider() }
                        row(part)
                    }
                }
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            }
            .padding(.vertical, 14)

            HStack {
                if !(segment.roots ?? []).isEmpty {
                    Button("Explore These Folders") { exploreAll() }
                }
                Spacer()
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 560, height: 520)
    }

    private func row(_ part: StorageSegment.Part) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(part.name).fontWeight(.medium)
                    if let verdict = part.verdict {
                        Text(verdict.label)
                            .font(.caption)
                            .foregroundStyle(verdict.color)
                            .padding(.horizontal, 6).padding(.vertical, 1)
                            .overlay(Capsule().strokeBorder(verdict.color.opacity(0.5)))
                    }
                }
                if let note = part.note {
                    Text(note).font(.callout).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let action = part.action {
                    Button(title(action)) { perform(action) }
                        .controlSize(.small)
                        .padding(.top, 2)
                }
            }
            Spacer(minLength: 8)
            Text(ByteFormat.string(part.bytes)).monospacedDigit().foregroundStyle(.secondary)
        }
        .padding(12)
        .accessibilityElement(children: .contain)
    }

    private func title(_ action: StorageSegment.Part.Action) -> LocalizedStringKey {
        switch action {
        case .explore: return "Show in Space Explorer"
        case .category(let id): return id == "snapshots" ? "Review Snapshots" : "Review"
        case .settings: return "Open Software Update"
        }
    }
}
