//
//  DataStack+iCloud.swift
//  Project
//
//  Created by Ivan Ricardo Espitia  on 23/03/22.
//

import Foundation
import CoreData

extension DataStack {
    
    func migrateToICloudIfNeeded(modelName: String, containerURL: URL, model: NSManagedObjectModel, completion: @escaping (_ result: Bool) -> Void) {
        
        let filePath = "\(modelName).sqlite"
        let seedStoreURL = containerURL.appendingPathComponent(filePath)
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: seedStoreURL.path) {
                                    
            let coordinator: NSPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
            var seedStore: NSPersistentStore!
            
            do {
                seedStore = try coordinator.addPersistentStore(
                    ofType: NSSQLiteStoreType,
                    configurationName: nil,
                    at: seedStoreURL,
                    options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true])
                
                self.migrateToICloudFromStore(
                    modelName: modelName,
                    containerURL: containerURL,
                    seedStore: seedStore,
                    coordinator: coordinator) { result in
                        completion(result)
                    }
                
            } catch let error {
                print("Error migrating \(error)")
                completion(false)
            }
        } else {
            print("no local database located")
            completion(false)
        }
    }
        
 
    func migrateToICloudFromStore(modelName: String, containerURL: URL, seedStore: NSPersistentStore, coordinator: NSPersistentStoreCoordinator, completion:  @escaping (_ result: Bool) -> Void) {
        let queue = OperationQueue()
        queue.addOperation({ () -> Void in
            do {
                let filePath = "\(modelName)iCloud.sqlite"
                let storeURL = containerURL.appendingPathComponent(filePath)
                try coordinator.migratePersistentStore(seedStore,
                                                       to: storeURL,
                                                       options: [NSMigratePersistentStoresAutomaticallyOption:true,NSInferMappingModelAutomaticallyOption:true],
                                                       withType: NSSQLiteStoreType)
                completion(true)
            } catch let error {
                print("Error migrating \(error)")
                completion(false)
            }
        })
    }
    
    
}
