//
//  DataStack+iCloud.swift
//  Project
//
//  Created by Ivan Ricardo Espitia  on 23/03/22.
//

import Foundation
import CoreData

extension DataStack {
    
    /**
     Verify if the database has backup data in iCloud, and restore data and model from iCloud
     
     date: 29-06-2022
     */
    func hasBackup(name: String, containerURL: URL, model: NSManagedObjectModel) -> Bool {
        let filePath = "\(name)iCloud.sqlite"
        let storeURL = containerURL.appendingPathComponent(filePath)
        let coordinator: NSPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        do {
            try coordinator.addPersistentStore(
                ofType: NSSQLiteStoreType,
                configurationName: nil,
                at: storeURL,
                options: [NSPersistentStoreRebuildFromUbiquitousContentOption: true])
            return true
        } catch let error {
            Logger.logError(with: "Error \(error)")
            return false
        }
    }
    
    /**
     Migrate local container to remote iCloud
     verifiying if the container exist or not to create one
     
     date: 23-03-2022
     */
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
        
 
    /**
     Migrate local container to remote iCloud
     
     date:23-03-2022
     */
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
