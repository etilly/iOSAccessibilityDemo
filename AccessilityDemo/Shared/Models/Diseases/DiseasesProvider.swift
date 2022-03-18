//
//  DiseasesProvider.swift
//  AccessilityDemo
//
//  Created by Erwan BOUET on 17/03/2022.
//

import CoreData
import OSLog

class DiseasesProvider {
    /// URL of dataset
    private let url: URL = URL(string: "https://api.orphacode.org/EN/ClinicalEntity")!
    
    /// Logger for provider
    private let logger = Logger(subsystem: "com.example.AccessilityDemo", category: "persistence")
    
    // CoreData container
    
    /// A persistent container to set up the Core Data stack.
    static var container: NSPersistentContainer = {
        /// - Tag: persistentContainer
        let container = NSPersistentContainer(name: "Diseases")

        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }
        
        // Enable persistent store remote change notifications
        /// - Tag: persistentStoreRemoteChange
        description.setOption(true as NSNumber,
                              forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // Enable persistent history tracking
        /// - Tag: persistentHistoryTracking
        description.setOption(true as NSNumber,
                              forKey: NSPersistentHistoryTrackingKey)

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        // This sample refreshes UI by consuming store changes via persistent history tracking.
        /// - Tag: viewContextMergeParentChanges
        container.viewContext.automaticallyMergesChangesFromParent = false
        container.viewContext.name = "viewContext"
        /// - Tag: viewContextMergePolicy
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.undoManager = nil
        container.viewContext.shouldDeleteInaccessibleFaults = true
        
        return container
    }()
    
    /// Fetches the disease from the remote server. Stored object in Core Data.
    func fetchDiseases() async throws {
        let session = URLSession.shared

        var urlRequest = URLRequest(url: url)
        urlRequest.addValue("NijiAccessbilityDemo", forHTTPHeaderField: "apiKey")
        urlRequest.addValue("application/json", forHTTPHeaderField: "accept")
        urlRequest.addValue("application/json", forHTTPHeaderField: "content-type")
        
        guard let (data, response) = try? await session.data(for: urlRequest),
              let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200
        else {
            logger.debug("Failed to received valid response and/or data.")
            throw DiseaseError.missingData
        }

        do {
            // Decode the GeoJSON into a data model.
            let jsonDecoder = JSONDecoder()
            let formatter = DateFormatter()
            formatter.dateFormat = "YYYY-MM-DD hh:mm:ss"
            jsonDecoder.dateDecodingStrategy = .formatted(formatter)
            let diseases = try jsonDecoder.decode([DiseaseResponse].self, from: data)
            logger.debug("Received \(diseases.count) records.")

            // Import the GeoJSON into Core Data.
            logger.debug("Start importing data to the store...")
            try await importDiseases(from: diseases)
            logger.debug("Finished importing data.")
        } catch let error {
            logger.error("Error: \(error.localizedDescription)")

            throw DiseaseError.wrongDataFormat(error: error)
        }
    }
    
    /// Import diseases in CoreData in private queue.
    func importDiseases(from response: [DiseaseResponse]) async throws {
        guard !response.isEmpty else { return }

        let taskContext = newTaskContext()
        // Add name and author to identify source of persistent history changes.
        taskContext.name = "importContext"
        taskContext.transactionAuthor = "importQuakes"

        /// - Tag: performAndWait
        try await taskContext.perform {
            // Execute the batch insert.
            /// - Tag: batchInsertRequest
            let batchInsertRequest = self.newBatchInsertRequest(with: response)
            if let fetchResult = try? taskContext.execute(batchInsertRequest),
               let batchInsertResult = fetchResult as? NSBatchInsertResult,
               let success = batchInsertResult.result as? Bool, success {
                return
            }
            
            self.logger.debug("Failed to execute batch insert request.")
            throw DiseaseError.insertError
        }

        logger.debug("Successfully inserted data.")
    }
}

private extension DiseasesProvider {
    /// Creates and configures a private queue context.
    func newTaskContext() -> NSManagedObjectContext {
        // Create a private queue context.
        /// - Tag: newBackgroundContext
        let taskContext = Self.container.newBackgroundContext()
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        // Set unused undoManager to nil for macOS (it is nil by default on iOS)
        // to reduce resource requirements.
        taskContext.undoManager = nil
        return taskContext
    }
    
    func newBatchInsertRequest(with propertyList: [DiseaseResponse]) -> NSBatchInsertRequest {
        var index = 0
        let total = propertyList.count

        // Provide one dictionary at a time when the closure is called.
        let batchInsertRequest = NSBatchInsertRequest(entity: Disease.entity(),
                                                      dictionaryHandler: { dictionary in
            guard index < total else { return true }
            dictionary.addEntries(from: propertyList[index].dictionnaryValue)
            index += 1
            return false
        })
        return batchInsertRequest
    }
}
