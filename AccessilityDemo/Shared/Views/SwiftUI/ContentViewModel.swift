//
//  ContentViewModel.swift
//  AccessilityDemo
//
//  Created by Erwan BOUET on 12/03/2022.
//

import Foundation
import CoreData
import SwiftUI
import Combine
import Algorithms

extension ContentView {
    @MainActor
    class ContentViewModel: ObservableObject {
        @Published var isLoading = false
        @Published var error: Error?
        @Published var searchText: String = ""
        @Published var diseases: [Disease] = []
        @Published var diseasesFiltered: [Disease] = []
        
        private let diseasesProvider = DiseasesProvider()
        private var cancellables = Set<AnyCancellable>()
        
        init() {
            try? fetchLocalDiseases()
            
            // combine diseases and current searched text
            let publisher = $diseases.combineLatest($searchText)
                .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
                .map { (diseases, filter) -> [Disease] in
                    guard !filter.isEmpty else {
                        return diseases
                    }
                    
                    return diseases.filter { $0.name.lowercased().contains(filter.lowercased()) }
                }
                .eraseToAnyPublisher()
            
            // assign to filtered diseases
            publisher
                .assign(to: \.diseasesFiltered, on: self)
                .store(in: &cancellables)
        }
        
        func fetchDiseases() async {
            isLoading = true
            
            do {
                try await diseasesProvider.fetchDiseases()
                try fetchLocalDiseases()
            } catch let error {
                self.error = error
            }
            
            isLoading = false
        }
        
        func fetchLocalDiseases() throws {
            let result = try DiseasesProvider.container.viewContext.fetch(Disease.fetchRequest())
            diseases = result as? [Disease] ?? diseases
        }
    }
}

