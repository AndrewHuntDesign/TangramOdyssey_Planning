//
//  ContentView.swift
//  TangramOdyssey
//

import SwiftUI

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(ProgressStore.self) private var progress
    @State private var catalog: PuzzleCatalog?
    @State private var loadError: String?
    @State private var selectedCategory: String?
    @State private var selectedPuzzle: Puzzle?

    var body: some View {
        Group {
            if let error = loadError {
                NavigationStack {
                    ContentUnavailableView("Couldn't load puzzles",
                                           systemImage: "exclamationmark.triangle",
                                           description: Text(error))
                        .navigationTitle("Tangram Odyssey")
                }
            } else if let catalog {
                if horizontalSizeClass == .regular {
                    iPadRoot(catalog)
                } else {
                    iPhoneRoot(catalog)
                }
            } else {
                ProgressView()
            }
        }
        .task {
            do {
                let puzzles = try await Task.detached {
                    try PuzzleLoader.loadAll()
                }.value
                let loadedCatalog = PuzzleCatalog(puzzles)
                catalog = loadedCatalog
                selectedCategory = loadedCatalog.categories.first
                selectedPuzzle = selectedCategory.flatMap { loadedCatalog.puzzles(in: $0).first }
            } catch {
                loadError = String(describing: error)
            }
        }
    }

    private func iPhoneRoot(_ catalog: PuzzleCatalog) -> some View {
        NavigationStack {
            CategoryListView(catalog: catalog)
                .navigationTitle("Tangram Odyssey")
                .toolbar { progressToolbar(catalog) }
                .navigationDestination(for: CategoryRef.self) { ref in
                    CategoryPuzzlesView(category: ref.name, puzzles: catalog.puzzles(in: ref.name))
                }
                .navigationDestination(for: Puzzle.self) { puzzle in
                    GameBoardView(puzzle: puzzle)
                }
        }
    }

    private func iPadRoot(_ catalog: PuzzleCatalog) -> some View {
        iPadCatalogView(catalog: catalog,
                        selectedCategory: $selectedCategory,
                        selectedPuzzle: $selectedPuzzle)
        .toolbar { progressToolbar(catalog) }
    }

    @ToolbarContentBuilder
    private func progressToolbar(_ catalog: PuzzleCatalog) -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Label("\(progress.solvedCount) / \(catalog.all.count)", systemImage: "checkmark.seal.fill")
                .labelStyle(.titleAndIcon)
                .font(.callout.weight(.medium))
                .foregroundStyle(.green)
        }
    }
}

private struct iPadCatalogView: View {
    let catalog: PuzzleCatalog
    @Binding var selectedCategory: String?
    @Binding var selectedPuzzle: Puzzle?

    var body: some View {
        NavigationSplitView {
            iPadCategorySidebar(catalog: catalog, selectedCategory: $selectedCategory)
                .navigationTitle("Tangram Odyssey")
        } content: {
            if let selectedCategory {
                iPadPuzzleGrid(category: selectedCategory,
                               puzzles: catalog.puzzles(in: selectedCategory),
                               selectedPuzzle: $selectedPuzzle)
            } else {
                ContentUnavailableView("Choose a category", systemImage: "square.grid.2x2")
            }
        } detail: {
            if let selectedPuzzle {
                GameBoardView(puzzle: selectedPuzzle) {
                    // In split view, Done clears the detail selection instead of dismissing a push.
                    self.selectedPuzzle = nil
                }
                    .id(selectedPuzzle.id)
            } else {
                ContentUnavailableView("Choose a puzzle",
                                       systemImage: "puzzlepiece.extension",
                                       description: Text("Select a puzzle to start playing."))
            }
        }
        .onChange(of: selectedCategory) { _, category in
            selectedPuzzle = category.flatMap { catalog.puzzles(in: $0).first }
        }
    }
}

private struct iPadCategorySidebar: View {
    let catalog: PuzzleCatalog
    @Binding var selectedCategory: String?
    @Environment(ProgressStore.self) private var progress

    var body: some View {
        List(catalog.categories, id: \.self, selection: $selectedCategory) { category in
            VStack(alignment: .leading, spacing: 2) {
                Text(category)
                    .font(.headline)
                Text(progressText(for: category))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
            .tag(category)
            .accessibilityIdentifier("category-\(category)")
        }
    }

    private func progressText(for category: String) -> String {
        let puzzles = catalog.puzzles(in: category)
        let solved = puzzles.reduce(0) { $0 + (progress.isSolved($1.id) ? 1 : 0) }
        return "\(solved) of \(puzzles.count) solved"
    }
}

private struct iPadPuzzleGrid: View {
    let category: String
    let puzzles: [Puzzle]
    @Binding var selectedPuzzle: Puzzle?
    @Environment(ProgressStore.self) private var progress

    private let columns = [GridItem(.adaptive(minimum: 132), spacing: 18)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(puzzles) { puzzle in
                    Button {
                        selectedPuzzle = puzzle
                    } label: {
                        thumbnail(puzzle)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("puzzle-\(puzzle.id)")
                }
            }
            .padding()
        }
        .navigationTitle(category)
    }

    private func thumbnail(_ puzzle: Puzzle) -> some View {
        let solved = progress.isSolved(puzzle.id)
        let selected = selectedPuzzle?.id == puzzle.id

        return VStack(spacing: 8) {
            PuzzleView(puzzle: puzzle,
                       style: solved ? .solution : .silhouette(.primary),
                       padding: 10)
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .background(.quaternary, in: .rect(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(selected ? Color.accentColor : .clear, lineWidth: 3)
                }
                .overlay(alignment: .topTrailing) {
                    if solved {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                            .padding(7)
                    }
                }

            Text(puzzle.name)
                .font(.caption)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .foregroundStyle(.secondary)
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
