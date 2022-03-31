//
//  ContentView.swift
//  Shared
//
//  Created by Erwan BOUET on 12/03/2022.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel: ContentViewModel

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.diseasesFiltered) { disease in
                    Text(disease.name)
                }
            }
            .listStyle(.sidebar)
            .searchable(text: $viewModel.searchText)
            .navigationTitle("AccessibilityDemo")
            .refreshable {
                await viewModel.fetchDiseases()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView(viewModel: .init())
                .previewDevice("iPhone 13")
        }
    }
}
