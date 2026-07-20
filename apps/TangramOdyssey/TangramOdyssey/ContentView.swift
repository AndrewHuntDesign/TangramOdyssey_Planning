//
//  ContentView.swift
//  TangramOdyssey
//

import SwiftUI

struct ContentView: View {
    @Environment(ProgressStore.self) private var progress
    @State private var catalog: PuzzleCatalog?
    @State private var loadError: String?

    var body: some View {
        NavigationStack {
            Group {
                if let error = loadError {
                    ContentUnavailableView("Couldn't load puzzles",
                                           systemImage: "exclamationmark.triangle",
                                           description: Text(error))
                } else if let catalog {
                    CategoryListView(catalog: catalog)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Tangram Odyssey")
            .toolbar {
                if let catalog {
                    ToolbarItem(placement: .topBarTrailing) {
                        Label("\(progress.solvedCount) / \(catalog.all.count)", systemImage: "checkmark.seal.fill")
                            .labelStyle(.titleAndIcon)
                            .font(.callout.weight(.medium))
                            .foregroundStyle(.green)
                    }
                }
            }
            .navigationDestination(for: CategoryRef.self) { ref in
                if let catalog {
                    CategoryPuzzlesView(category: ref.name, puzzles: catalog.puzzles(in: ref.name))
                }
            }
            .navigationDestination(for: Puzzle.self) { puzzle in
                GameBoardView(puzzle: puzzle)
            }
        }
        .task {
            do { catalog = PuzzleCatalog(try PuzzleLoader.loadAll()) }
            catch { loadError = String(describing: error) }
        }
    }
}

#Preview {
    ContentView()
        .environment(ProgressStore())
}

#Preview("With progress") {
    let store = ProgressStore(defaults: UserDefaults(suiteName: "preview")!)
    store.markSolved(1)
    return ContentView().environment(store)
}
