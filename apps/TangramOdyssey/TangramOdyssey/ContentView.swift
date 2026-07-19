//
//  ContentView.swift
//  TangramOdyssey
//

import SwiftUI

struct ContentView: View {
    @State private var puzzles: [Puzzle] = []
    @State private var index = 0
    @State private var showSolution = true
    @State private var loadError: String?

    private var current: Puzzle? {
        puzzles.indices.contains(index) ? puzzles[index] : nil
    }

    var body: some View {
        VStack(spacing: 16) {
            if let error = loadError {
                ContentUnavailableView("Couldn't load puzzles", systemImage: "exclamationmark.triangle", description: Text(error))
            } else if let puzzle = current {
                header(for: puzzle)

                PuzzleView(puzzle: puzzle,
                           style: showSolution ? .solution : .silhouette(.primary))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.quaternary, in: .rect(cornerRadius: 20))

                controls
            } else {
                ProgressView()
            }
        }
        .padding()
        .task {
            do { puzzles = try PuzzleLoader.loadAll() }
            catch { loadError = String(describing: error) }
        }
    }

    private func header(for puzzle: Puzzle) -> some View {
        VStack(spacing: 4) {
            Text(puzzle.name).font(.title2.bold())
            Text(puzzle.categories.joined(separator: " · "))
                .font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Toggle("Show solution", isOn: $showSolution)
                .toggleStyle(.button)

            HStack {
                Button { step(-1) } label: { Image(systemName: "chevron.left") }
                    .disabled(index == 0)
                Spacer()
                Text("\(index + 1) of \(puzzles.count)")
                    .font(.callout.monospacedDigit()).foregroundStyle(.secondary)
                Spacer()
                Button { step(1) } label: { Image(systemName: "chevron.right") }
                    .disabled(index >= puzzles.count - 1)
            }
            .font(.title2)
            .buttonStyle(.bordered)
        }
    }

    private func step(_ delta: Int) {
        index = min(max(0, index + delta), puzzles.count - 1)
    }
}

#Preview {
    ContentView()
}
