//
//  NSEntityDescription+PrimaryKey.swift
//  Project
//
//  Created by Ivan Ricardo Espitia  on 16/03/22.
//

//  Converted to Swift 5.5 by Swiftify v5.5.24623 - https://swiftify.com/
import CoreData

public let SyncDefaultLocalPrimaryKey = "id"
public let SyncDefaultLocalCompatiblePrimaryKey = "remoteID"
public let SyncDefaultRemotePrimaryKey = "id"

extension NSEntityDescription {
    
    /// Returns the Core Data attribute used as the primary key. By default it will look for the attribute named `id`.
    /// You can mark any attribute as primary key by adding `sync.isPrimaryKey` and the value `YES` to the Core Data model userInfo.
    /// - Returns: The attribute description that represents the primary key.
    func sync_primaryKeyAttribute() -> NSAttributeDescription? {
    
        var primaryKeyAttribute: NSAttributeDescription?
        
        for (keyx, propertyDescription) in self.propertiesByName {
            if propertyDescription is NSAttributeDescription {
                if propertyDescription.isCustomPrimaryKey() {
                    primaryKeyAttribute = propertyDescription as? NSAttributeDescription
                }                
                if keyx == SyncDefaultLocalPrimaryKey || keyx == SyncDefaultLocalCompatiblePrimaryKey {
                    primaryKeyAttribute = propertyDescription as? NSAttributeDescription
                }
            }
        }
        
        return primaryKeyAttribute
    }

    /// Returns the local primary key for the entity.
    /// - Returns: The name of the attribute that represents the local primary key;.
    func sync_localPrimaryKey() -> String {
        let primaryAttribute = sync_primaryKeyAttribute()
        let localKey = primaryAttribute?.name
        return localKey ?? ""
    }

    /// Returns the remote primary key for the entity.
    /// - Returns: The name of the attribute that represents the remote primary key.
    func sync_remotePrimaryKey() -> String {
        let primaryKeyAttribute = sync_primaryKeyAttribute()
        var remoteKey = primaryKeyAttribute?.customKey()

        if remoteKey == nil {
            if primaryKeyAttribute?.name == SyncDefaultLocalPrimaryKey || primaryKeyAttribute?.name == SyncDefaultLocalCompatiblePrimaryKey {
                remoteKey = SyncDefaultRemotePrimaryKey
            } else {
                remoteKey = primaryKeyAttribute?.name.camelCaseToSnakeCase()
            }
        }

        return remoteKey ?? ""
    }
}

