//
//  CategoryListView.swift
//  TangramOdyssey
//
//  Root browse screen: the categories ("packs"), each showing solved / total progress.
//

import SwiftUI

struct CategoryListView: View {
    let catalog: PuzzleCatalog
    @Environment(ProgressStore.self) private var progress

    var body: some View {
        List(catalog.categories, id: \.self) { category in
            NavigationLink(value: CategoryRef(name: category)) {
                row(for: category)
            }
            .accessibilityIdentifier("category-\(category)")
        }
    }

    private func row(for category: String) -> some View {
        let puzzles = catalog.puzzles(in: category)
        let total = puzzles.count
        let solved = puzzles.reduce(0) { $0 + (progress.isSolved($1.id) ? 1 : 0) }

        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(category).font(.headline)
                Text("\(solved) of \(total) solved")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if total > 0, solved == total {
                Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }
}
