//
//  ContentViewModel.swift
//  AccessilityDemo
//
//  Created by Erwan BOUET on 12/03/2022.
//

import Foundation
import CoreData
import SwiftUI

extension ContentView {
    @MainActor
    class ContentViewModel: ObservableObject {
        @Published var isLoading = false
        @Published var error: Error?
        @Published var searchText: String = ""
        @Published var diseases: [Disease] = []
        
        private let diseasesProvider = DiseasesProvider()
        
        func fetchDiseases() async {
            isLoading = true
            
            do {
                try await diseasesProvider.fetchDiseases()
                let result = try DiseasesProvider.container.viewContext.fetch(Disease.fetchRequest())
                diseases = result as? [Disease] ?? diseases
            } catch let error {
                self.error = error
            }
            
            isLoading = false
        }
    }
}

