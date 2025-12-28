import SwiftUI
import SwiftData

struct SetRowView: View {
    @Bindable var set: WorkoutSet
    let modelContext: ModelContext
    let workout: ActiveWorkout
    let showLabels: Bool
    let onSetComplete: (Int?, String, Int) -> Void
    let onDeleteSet: (WorkoutSet) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {

            // Set number
            ZStack {
                Circle()
                    .fill(AppTheme.cardTertiary)
                    .frame(width: 28, height: 28)
                Text("\(set.setNumber)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .frame(width: 60, alignment: .leading)

            // Reps
            TextField("Reps", value: $set.reps, format: .number)
                .keyboardType(.numberPad)
                .textFieldStyle(.plain)
                .padding(6)
                .frame(width: 80)
                .background(AppTheme.cardTertiary)
                .cornerRadius(6)
                .onChange(of: set.reps) { _, _ in
                    try? modelContext.save()
                }

            // Weight
            TextField("Weight", value: $set.weight, format: .number)
                .keyboardType(.decimalPad)
                .textFieldStyle(.plain)
                .padding(6)
                .frame(width: 80)
                .background(AppTheme.cardTertiary)
                .cornerRadius(6)
                .onChange(of: set.weight) { _, _ in
                    try? modelContext.save()
                }

            Spacer()

            // Completion toggle
            Button {
                // Dismiss keyboard
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                
                let wasComplete = set.completedAt != nil
                set.completedAt = wasComplete ? nil : Date()
                try? modelContext.save()

                if !wasComplete,
                   let rest = set.restTime,
                   rest > 0,
                   let entry = set.workoutEntry,
                   let sets = entry.sets?.sorted(by: { $0.setNumber < $1.setNumber }),
                   let index = sets.firstIndex(where: { $0.id == set.id }),
                   index + 1 < sets.count {

                    onSetComplete(rest, entry.exerciseName, sets[index + 1].setNumber)
                }
            } label: {
                Image(systemName: set.completedAt != nil ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(
                        set.completedAt != nil
                        ? AppTheme.accentPrimary
                        : AppTheme.textTertiary
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 0)
        .background(
            set.completedAt != nil
            ? AppTheme.accentPrimary.opacity(0.15)
            : AppTheme.cardPrimary
        )
        .cornerRadius(4)
    }
}
