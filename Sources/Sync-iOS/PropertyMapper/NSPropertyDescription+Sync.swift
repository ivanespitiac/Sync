//
//  NSPropertyDescription+Sync.swift
//  Project
//
//  Created by Ivan Ricardo Espitia  on 16/03/22.
//

import Foundation
import CoreData

private let SyncCustomLocalPrimaryKey = "sync.isPrimaryKey"
private let SyncCompatibilityCustomLocalPrimaryKey = "hyper.isPrimaryKey"
private let SyncCustomLocalPrimaryKeyValue = "YES"
private let SyncCustomLocalPrimaryKeyAlternativeValue = "true"

private let SyncCustomRemoteKey = "sync.remoteKey"
private let SyncCompatibilityCustomRemoteKey = "hyper.remoteKey"

private let PropertyMapperNonExportableKey = "sync.nonExportable"
private let PropertyMapperCompatibilityNonExportableKey = "hyper.nonExportable"

private let PropertyMapperCustomValueTransformerKey = "sync.valueTransformer"
private let PropertyMapperCompatibilityCustomValueTransformerKey = "hyper.valueTransformer"

extension NSPropertyDescription {
    
    func isCustomPrimaryKey() -> Bool {
        var keyName = self.userInfo?[SyncCustomLocalPrimaryKey] as? String
        if keyName == nil {
            keyName = self.userInfo?[SyncCompatibilityCustomLocalPrimaryKey] as? String
        }
        let hasCustomPrimaryKey = keyName != nil
        && keyName == SyncCustomLocalPrimaryKeyValue
        || keyName == SyncCustomLocalPrimaryKeyAlternativeValue
        
        return hasCustomPrimaryKey
    }
    
    
    func customKey() -> String? {
        var keyName = self.userInfo?[SyncCustomRemoteKey] as? String
        if (keyName == nil) {
            keyName = self.userInfo?[SyncCompatibilityCustomRemoteKey] as? String
        }
        return keyName
    }
    
    func shouldExportAttribute() -> Bool {
        var nonExportableKey = self.userInfo?[PropertyMapperNonExportableKey] as? String
        if (nonExportableKey == nil) {
            nonExportableKey = self.userInfo?[PropertyMapperCompatibilityNonExportableKey] as? String
        }
        return nonExportableKey == nil
    }
    
    func customTransformerName() -> String? {
        var keyName = self.userInfo?[PropertyMapperCustomValueTransformerKey] as? String
        if (keyName == nil) {
            keyName = self.userInfo?[PropertyMapperCompatibilityCustomValueTransformerKey] as? String
        }
        return keyName
    }
    
}
