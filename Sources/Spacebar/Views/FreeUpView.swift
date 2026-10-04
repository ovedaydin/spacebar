import SpacebarCore
import SwiftUI

/// "Free up 20 GB": pick a target, see the plan (safest first), approve once.
struct FreeUpView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var gigabytes = 10
    @State private var deleteNow = true

    var body: some View {
        let plan = model.freeUpPlan(target: Int64(gigabytes) * 1_000_000_000)
        VStack(alignment: .leading, spacing: 14) {
            Text("Free Up Space").font(.title2.weight(.semibold))
            HStack {
                Text("Free up")
                Picker("Target", selection: $gigabytes) {
                    ForEach([1, 5, 10, 20, 50, 100], id: \.self) { Text("\($0) GB").tag($0) }
                }
                .labelsHidden()
                .fixedSize()
                Spacer()
            }
            if model.showingCachedResults {
                Label("Spacebar is still checking the results from last time. Try again in a moment.", systemImage: "hourglass")
                    .foregroundStyle(.secondary)
            }
            if plan.steps.isEmpty {
                Text("Nothing to suggest right now.").foregroundStyle(.secondary)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(tiers(plan), id: \.self) { tier in
                            Text(tier.label).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                            ForEach(plan.steps.filter { $0.tier == tier }) { step in
                                HStack {
                                    Image(systemName: step.category.icon).frame(width: 20).foregroundStyle(.secondary)
                                    Text(step.category.name)
                                    Text("\(step.items.count) items").foregroundStyle(.secondary)
                                    Spacer()
                                    Text(ByteFormat.string(step.bytes)).monospacedDigit()
                                }
                            }
                        }
                    }
                    .padding(12)
                }
                .frame(maxHeight: 260)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                ProgressView(value: Double(min(plan.total, plan.target)), total: Double(max(plan.target, 1)))
                Text(plan.reachesTarget
                     ? String(localized: "This plan frees \(ByteFormat.string(plan.total)).")
                     : String(localized: "Spacebar can safely free \(ByteFormat.string(plan.total)). For more, look at Large Files, Media Review or Offload."))
                    .foregroundStyle(.secondary)
                Toggle("Delete what goes to the Trash right away, so the space is free now", isOn: $deleteNow)
                    .help("Only the items this plan moves to the Trash; anything else in your Trash is left alone. Off: they stay in the Trash, so you can still put them back.")
            }
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)
                Button(model.dryRun ? "Simulate" : "Free \(ByteFormat.string(plan.total))") {
                    model.run(plan, deleteTrashedNow: deleteNow)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(plan.steps.isEmpty || model.cleaning || model.showingCachedResults)
            }
        }
        .padding(20)
        .frame(width: 480)
    }

    private func tiers(_ plan: FreeUpPlan) -> [FreeUpPlan.Tier] {
        Array(Set(plan.steps.map(\.tier))).sorted()
    }
}
