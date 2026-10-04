import SpacebarCore
import SwiftUI

/// A sidebar section of categories. Those that found nothing fold into one row, so the sidebar
/// shows what matters; the category being viewed always stays visible.
struct CategorySection: View {
    @EnvironmentObject private var model: AppModel
    let title: LocalizedStringKey
    let group: CleanCategory.Group
    let route: Route?
    @AppStorage("sidebarShowsEmpty") private var showsEmpty = false

    var body: some View {
        let all = model.categories.filter { $0.group == group }
        let empty = all.filter(isEmpty)
        Section(title) {
            ForEach(all.filter { !isEmpty($0) || showsEmpty }) { category in
                SidebarRow(category: category).tag(Route.category(category.id))
            }
            if !empty.isEmpty {
                Button { showsEmpty.toggle() } label: {
                    Label(showsEmpty ? String(localized: "Hide empty") : String(localized: "\(empty.count) with nothing found"),
                          systemImage: showsEmpty ? "chevron.up" : "chevron.down")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .font(.callout)
            }
        }
    }

    /// Scanned, nothing found, and not the page being shown.
    private func isEmpty(_ category: CleanCategory) -> Bool {
        guard model.results[category.id] != nil, !model.scanning.contains(category.id) else { return false }
        return model.items(category.id).isEmpty && route != .category(category.id)
    }
}
