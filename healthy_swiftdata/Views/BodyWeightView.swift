//
//  BodyWeightView.swift
//  healthy_swiftdata
//
//  Created by Matthew Corcoran on 25/12/2025.
//

import SwiftUI
import SwiftData

struct BodyWeightView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BodyWeightEntry.recordedAt, order: .reverse) private var weightEntries: [BodyWeightEntry]
    
    @State private var showingAddSheet = false
    @State private var entryToEdit: BodyWeightEntry?
    @State private var entryToDelete: BodyWeightEntry?
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            Group {
                if weightEntries.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(weightEntries) { entry in
                            BodyWeightRow(entry: entry)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button {
                                        entryToEdit = entry
                                        showingAddSheet = true
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                    
                                    Button(role: .destructive) {
                                        entryToDelete = entry
                                        showingDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .navigationTitle("Weight History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        entryToEdit = nil
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                BodyWeightEntryForm(entry: entryToEdit) { weight, unit, date, notes in
                    saveEntry(weight: weight, unit: unit, recordedAt: date, notes: notes)
                }
            }
            .alert("Delete Weight Entry", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let entry = entryToDelete {
                        deleteEntry(entry)
                    }
                }
            } message: {
                if let entry = entryToDelete {
                    Text("Are you sure you want to delete this weight entry?")
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "scalemass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("No Weight Entries")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Tap + to record your weight")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func saveEntry(weight: Double, unit: String, recordedAt: Date, notes: String?) {
        if let entry = entryToEdit {
            // Update existing entry
            entry.weight = weight
            entry.unit = unit
            entry.recordedAt = recordedAt
            entry.notes = notes
            try? modelContext.save()
        } else {
            // Create new entry
            let newEntry = BodyWeightEntry(
                weight: weight,
                unit: unit,
                recordedAt: recordedAt,
                notes: notes
            )
            modelContext.insert(newEntry)
            try? modelContext.save()
        }
        entryToEdit = nil
    }
    
    private func deleteEntry(_ entry: BodyWeightEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
        entryToDelete = nil
    }
}

struct BodyWeightRow: View {
    let entry: BodyWeightEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(String(format: "%.1f", entry.weight)) \(entry.unit)")
                    .font(.headline)
                Spacer()
                Text(entry.recordedAt, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text(entry.recordedAt, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let notes = entry.notes, !notes.isEmpty {
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    BodyWeightView()
        .modelContainer(for: [BodyWeightEntry.self], inMemory: true)
}

