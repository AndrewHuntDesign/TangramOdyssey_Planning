//
//  CategoryPuzzlesView.swift
//  TangramOdyssey
//
//  A grid of puzzle thumbnails within a category. Unsolved puzzles show their silhouette (the
//  challenge); solved puzzles show the colored solution with a checkmark. Tapping plays.
//

import SwiftUI

struct CategoryPuzzlesView: View {
    let category: String
    let puzzles: [Puzzle]
    @Environment(ProgressStore.self) private var progress

    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(puzzles) { puzzle in
                    NavigationLink(value: puzzle) {
                        thumbnail(puzzle)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("puzzle-\(puzzle.id)")
                }
            }
            .padding()
        }
        .navigationTitle(category)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func thumbnail(_ puzzle: Puzzle) -> some View {
        let solved = progress.isSolved(puzzle.id)
        return VStack(spacing: 6) {
            PuzzleView(puzzle: puzzle,
                       style: solved ? .solution : .silhouette(.primary),
                       padding: 8)
                .frame(height: 96)
                .frame(maxWidth: .infinity)
                .background(.quaternary, in: .rect(cornerRadius: 12))
                .overlay(alignment: .topTrailing) {
                    if solved {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                            .padding(6)
                    }
                }

            Text(puzzle.name)
                .font(.caption2)
                .lineLimit(1)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        if let all = try? PuzzleLoader.loadAll() {
            let fishes = all.filter { $0.categories.contains("Fishes") }
            let store = ProgressStore(defaults: UserDefaults(suiteName: "gridPreview")!)
            fishes.prefix(3).forEach { store.markSolved($0.id) }
            return AnyView(CategoryPuzzlesView(category: "Fishes", puzzles: fishes).environment(store))
        } else {
            return AnyView(Text("Failed to load"))
        }
    }
}
