import SwiftUI

struct HistoryView: View {
    @State private var items: [HistoryItem] = []
    private let store = HistoryStore()

    var body: some View {
        List {
            ForEach(items) { item in
                NavigationLink(destination: ResultsViewRestored(item: item)) {
                    VStack(alignment: .leading) {
                        Text(item.registration).foregroundColor(.white)
                        Text(item.createdAt.formatted()).font(.footnote).foregroundColor(.gray)
                    }
                }
            }.onDelete(perform: delete)
        }
        .onAppear { load() }
        .navigationTitle("History")
        .preferredColorScheme(.dark)
    }

    private func load() { items = (try? store.list()) ?? [] }
    private func delete(at offsets: IndexSet) {
        for index in offsets { try? store.delete(id: items[index].id) }
        load()
    }
}

private struct ResultsViewRestored: View {
    let item: HistoryItem
    var body: some View {
        // Minimal restoration: re-show results in existing ResultsView context
        ResultsView()
    }
}

#Preview { NavigationStack { HistoryView() } }