import SpacebarCore
import SwiftUI

extension FolderGuide.Safety {
    var label: LocalizedStringKey {
        switch self {
        case .regenerates: return "Rebuilt when needed"
        case .safe: return "Safe to remove"
        case .review: return "Look before deleting"
        case .keep: return "Keep"
        }
    }

    var icon: String {
        switch self {
        case .regenerates: return "arrow.triangle.2.circlepath"
        case .safe: return "checkmark.circle"
        case .review: return "eye"
        case .keep: return "lock"
        }
    }

    var color: Color {
        switch self {
        case .regenerates, .safe: return .green
        case .review: return .orange
        case .keep: return .secondary
        }
    }
}

/// Asks the window to open a cleanup category (from the guide card).
enum GuideNavigation {
    static let openCategory = Notification.Name("Spacebar.openCategory")
}

/// "What is this?": a small tag on a row that opens the guide's card.
struct GuideTag: View {
    let match: FolderGuide.Match
    /// The folder's own name: when the guide's title just repeats it, only the icon is shown.
    var name: String? = nil
    @State private var showing = false

    var body: some View {
        let title = match.entry.title(FolderGuide.language)
        Button { showing.toggle() } label: {
            Label {
                if title.localizedCaseInsensitiveCompare(name ?? "") != .orderedSame {
                    Text(title).lineLimit(1)
                }
            } icon: {
                Image(systemName: match.entry.safety.icon)
            }
            .font(.caption)
            .foregroundStyle(match.entry.safety.color)
        }
        .buttonStyle(.plain)
        .help("What is this?")
        .popover(isPresented: $showing, arrowEdge: .bottom) { GuideCard(match: match) }
        .accessibilityLabel(Text("\(match.entry.title(FolderGuide.language)), \(Text(match.entry.safety.label))"))
    }
}

struct GuideCard: View {
    let match: FolderGuide.Match

    var body: some View {
        let entry = match.entry, language = FolderGuide.language
        VStack(alignment: .leading, spacing: 8) {
            if match.inside {
                Text("Inside").font(.caption).foregroundStyle(.secondary)
            }
            Text(entry.title(language)).font(.headline)
            Text(entry.what(language)).fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 6) {
                Text("Made by \(entry.by)").foregroundStyle(.secondary)
                Spacer()
                Label(entry.safety.label, systemImage: entry.safety.icon).foregroundStyle(entry.safety.color)
            }
            .font(.callout)
            if let category = entry.category {
                Button("Open in Cleanup") {
                    NotificationCenter.default.post(name: GuideNavigation.openCategory, object: category)
                }
            }
        }
        .padding(14)
        .frame(width: 320, alignment: .leading)
    }
}
