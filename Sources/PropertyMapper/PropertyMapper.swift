//
//  PropertyMapper.swift
//  Project
//
//  Created by Ivan Ricardo Espitia  on 16/03/22.
//

//  Converted to Swift 5.5 by Swiftify v5.5.24623 - https://swiftify.com/
import CoreData
import Foundation

var PropertyMapperVersionNumber = 0.0
let PropertyMapperVersionString: [UInt8] = []


/// The relationship type used to export the NSManagedObject as JSON.
/// - SyncPropertyMapperRelationshipTypeNone:   Skip all relationships.
/// - SyncPropertyMapperRelationshipTypeArray:  Normal JSON representation of relationships.
/// - SyncPropertyMapperRelationshipTypeNested: Uses Ruby on Rails's accepts_nested_attributes_for notation to represent relationships.
enum SyncPropertyMapperRelationshipType : Int {
    case none = 0
    case array
    case nested
}

/// The inflection type used to export the NSManagedObject as JSON.
/// - SyncPropertyMapperInflectionTypeSnakeCase: Uses snake_case notation.
/// - SyncPropertyMapperInflectionTypeCamelCase: Uses camelCase notation.
enum SyncPropertyMapperInflectionType : Int {
    case snakeCase = 0
    case camelCase
}

private let PropertyMapperNestedAttributesKey = "attributes"

/// Collection of helper methods to facilitate mapping JSON to NSManagedObject.
extension NSManagedObject {
    /// Fills the @c NSManagedObject with the contents of the dictionary using a convention-over-configuration paradigm mapping the Core Data attributes to their conterparts in JSON using snake_case.
    /// - Parameter dictionary: The JSON dictionary to be used to fill the values of your @c NSManagedObject.

    // MARK: - Public methods

    func fill(withDictionary dictionary: [String : Any?]) {
        hyp_fill(withDictionary: dictionary)
    }

    /// Fills the @c NSManagedObject with the contents of the dictionary using a convention-over-configuration paradigm mapping the Core Data attributes to their conterparts in JSON using snake_case.
    /// - Parameter dictionary: The JSON dictionary to be used to fill the values of your @c NSManagedObject.
    func hyp_fill(withDictionary dictionary: [String : Any?]) {
        
        for (key, value) in dictionary {
            
            let attributeDescription = self.attributeDescription(forRemoteKey: key)
            if let attributeDescription = attributeDescription {
                let valueExists = value != nil && !(value is NSNull)
                if valueExists && (value is [AnyHashable : Any]) && attributeDescription.attributeType != .binaryDataAttributeType {
                    let remoteKey = self.remoteKey(
                        for: attributeDescription,
                        inflectionType: SyncPropertyMapperInflectionType.snakeCase)
                    let hasCustomKeyPath = remoteKey != nil && remoteKey?.range(of: ".") != nil
                    if hasCustomKeyPath {
                        
                        if let keyPathAttributeDescriptions = attributeDescriptions(forRemoteKeyPath: remoteKey) {
                            for keyPathAttributeDescription in keyPathAttributeDescriptions {
                                guard let keyPathAttributeDescription = keyPathAttributeDescription as? NSAttributeDescription else {
                                    continue
                                }
                                let remoteKey = self.remoteKey(
                                    for: keyPathAttributeDescription,
                                    inflectionType: SyncPropertyMapperInflectionType.snakeCase)
                                
                                let localKey = keyPathAttributeDescription.name
                                
                                if let grapValue = dictionary[remoteKey ?? ""] {
                                    hyp_setDictionaryValue(
                                        grapValue,
                                        forKey: localKey,
                                        attributeDescription: keyPathAttributeDescription)
                                }
                                                                
                            }
                        }
                                               
                    }
                } else {
                    let localKey = attributeDescription.name
                    hyp_setDictionaryValue(
                        value,
                        forKey: localKey,
                        attributeDescription: attributeDescription)
                }
            }
        }
    }

    func hyp_setDictionaryValue(
        _ value: Any?,
        forKey key: String,
        attributeDescription: NSAttributeDescription
    ) {
       
        if let value = value {
            
            let processedValue = self.value(
                for: attributeDescription,
                usingRemoteValue: value)
            
            let localValue = self.value(forKey: key)
            
            if "\(String(describing: localValue))" != "\(String(describing: processedValue))" {
                setValue(processedValue, forKey: key)
            }
        } else {
            setValue(nil, forKey: key)
        }
                
    }

    /// Creates a @c NSDictionary of values based on the @c NSManagedObject subclass that can be serialized by @c NSJSONSerialization. Includes relationships to other models using Ruby on Rail's nested attributes model.
    /// @c NSDate objects will be stringified to the ISO-8601 standard.
    /// - Returns: The JSON representation of the @c NSManagedObject in the form of a @c NSDictionary.
    func hyp_dictionary() -> [String : Any?] {
        return self.hyp_dictionary(using: .snakeCase)
    }

    /// Creates a @c NSDictionary of values based on the @c NSManagedObject subclass that can be serialized by @c NSJSONSerialization. Includes relationships to other models using Ruby on Rail's nested attributes model.
    /// @c NSDate objects will be stringified to the ISO-8601 standard.
    /// - Parameter inflectionType: The type used to export the dictionary, can be camelCase or snakeCase.
    /// - Returns: The JSON representation of the @c NSManagedObject in the form of a @c NSDictionary.
    func hyp_dictionary(using inflectionType: SyncPropertyMapperInflectionType) -> [String : Any?] {
        return hyp_dictionary(
            with: defaultDateFormatter(),
            parent: nil,
            using: inflectionType,
            andRelationshipType: .nested)
    }

    func hyp_dictionaryUsinginflectionType(
        _ inflectionType: SyncPropertyMapperInflectionType,
        andRelationshipType relationshipType: SyncPropertyMapperRelationshipType
    ) -> [String : Any?] {
        return hyp_dictionary(
            with: defaultDateFormatter(),
            parent: nil,
            using: inflectionType,
            andRelationshipType: relationshipType)
    }

    /// Creates a @c NSDictionary of values based on the @c NSManagedObject subclass that can be serialized by @c NSJSONSerialization. Could include relationships to other models.
    /// @c NSDate objects will be stringified to the ISO-8601 standard.
    /// - Parameter relationshipType: It indicates wheter the result dictionary should include no relationships, nested attributes or normal attributes.
    /// - Returns: The JSON representation of the @c NSManagedObject in the form of a @c NSDictionary.
    func hyp_dictionary(using relationshipType: SyncPropertyMapperRelationshipType) -> [String : Any?] {
        return hyp_dictionary(
            with: defaultDateFormatter(),
            using: relationshipType)
    }

    /// Creates a @c NSDictionary of values based on the @c NSManagedObject subclass that can be serialized by @c NSJSONSerialization. Could include relationships to other models.
    /// @c NSDate objects will be stringified to the ISO-8601 standard.
    /// - Parameters:
    ///   - inflectionType: The type used to export the dictionary, can be camelCase or snakeCase.
    ///   - relationshipType: It indicates wheter the result dictionary should include no relationships, nested attributes or normal attributes.
    /// - Returns: The JSON representation of the @c NSManagedObject in the form of a @c NSDictionary.
    func hyp_dictionary(
        using inflectionType: SyncPropertyMapperInflectionType,
        andRelationshipType relationshipType: SyncPropertyMapperRelationshipType
    ) -> [String : Any?] {
        return hyp_dictionary(
            with: defaultDateFormatter(),
            parent: nil,
            using: inflectionType,
            andRelationshipType: relationshipType)
    }

    /// Creates a @c NSDictionary of values based on the @c NSManagedObject subclass that can be serialized by @c NSJSONSerialization. Includes relationships to other models using Ruby on Rail's nested attributes model.
    /// - Parameter dateFormatter: A custom date formatter that turns @c NSDate objects into NSString objects. Do not pass @c nil, instead use the @c hyp_dictionary method.
    /// - Returns: The JSON representation of the @c NSManagedObject in the form of a @c NSDictionary.
    func hyp_dictionary(with dateFormatter: DateFormatter) -> [String : Any?] {
        return hyp_dictionary(
            with: dateFormatter,
            parent: nil,
            using: .nested)
    }

    /// Creates a @c NSDictionary of values based on the @c NSManagedObject subclass that can be serialized by @c NSJSONSerialization. Could include relationships to other models using Ruby on Rail's nested attributes model.
    /// - Parameters:
    ///   - dateFormatter:    A custom date formatter that turns @c NSDate objects into @c NSString objects. Do not pass nil, instead use the 'hyp_dictionary' method.
    ///   - relationshipType: It indicates wheter the result dictionary should include no relationships, nested attributes or normal attributes.
    /// - Returns: The JSON representation of the @c NSManagedObject in the form of a @c NSDictionary.
    func hyp_dictionary(
        with dateFormatter: DateFormatter,
        using relationshipType: SyncPropertyMapperRelationshipType
    ) -> [String : Any?] {
        return hyp_dictionary(
            with: dateFormatter,
            parent: nil,
            using: relationshipType)
    }

    /// Creates a @c NSDictionary of values based on the @c NSManagedObject subclass that can be serialized by @c NSJSONSerialization. Could include relationships to other models using Ruby on Rail's nested attributes model.
    /// - Parameters:
    ///   - dateFormatter:    A custom date formatter that turns @c NSDate objects into @c NSString objects. Do not pass nil, instead use the 'hyp_dictionary' method.
    ///   - inflectionType: The type used to export the dictionary, can be camelCase or snakeCase.
    /// - Returns: The JSON representation of the @c NSManagedObject in the form of a @c NSDictionary.
    func hyp_dictionary(
        with dateFormatter: DateFormatter,
        using inflectionType: SyncPropertyMapperInflectionType
    ) -> [String : Any?] {
        return hyp_dictionary(
            with: dateFormatter,
            parent: nil,
            using: inflectionType,
            andRelationshipType: .nested)
    }

    /// Creates a @c NSDictionary of values based on the @c NSManagedObject subclass that can be serialized by @c NSJSONSerialization. Could include relationships to other models using Ruby on Rail's nested attributes model.
    /// - Parameters:
    ///   - dateFormatter:    A custom date formatter that turns @c NSDate objects into @c NSString objects. Do not pass nil, instead use the 'hyp_dictionary' method.
    ///   - inflectionType: The type used to export the dictionary, can be camelCase or snakeCase.
    ///   - relationshipType: It indicates wheter the result dictionary should include no relationships, nested attributes or normal attributes.
    /// - Returns: The JSON representation of the @c NSManagedObject in the form of a @c NSDictionary.
    func hyp_dictionary(
        with dateFormatter: DateFormatter,
        using inflectionType: SyncPropertyMapperInflectionType,
        andRelationshipType relationshipType: SyncPropertyMapperRelationshipType
    ) -> [String : Any?] {
        return hyp_dictionary(
            with: dateFormatter,
            parent: nil,
            using: inflectionType,
            andRelationshipType: relationshipType)
    }

    /// Creates a @c NSDictionary of values based on the @c NSManagedObject subclass that can be serialized by @c NSJSONSerialization. Could include relationships to other models using Ruby on Rail's nested attributes model.
    /// - Parameters:
    ///   - dateFormatter:    A custom date formatter that turns @c NSDate objects into @c NSString objects. Do not pass nil, instead use the @c hyp_dictionary method.
    ///   - parent:           The parent of the managed object.
    ///   - relationshipType: It indicates wheter the result dictionary should include no relationships, nested attributes or normal attributes.
    /// - Returns: The JSON representation of the @c NSManagedObject in the form of a @c NSDictionary.
    func hyp_dictionary(
        with dateFormatter: DateFormatter,
        parent: NSManagedObject?,
        using relationshipType: SyncPropertyMapperRelationshipType
    ) -> [String : Any?] {
        return hyp_dictionary(
            with: dateFormatter,
            parent: parent,
            using: .snakeCase,
            andRelationshipType: relationshipType)
    }

    func hyp_dictionary(
        with dateFormatter: DateFormatter,
        parent: NSManagedObject?,
        using inflectionType: SyncPropertyMapperInflectionType,
        andRelationshipType relationshipType: SyncPropertyMapperRelationshipType
    ) -> [String : Any?] {
        
        var managedObjectAttributes: [AnyHashable : Any] = [:]

        for propertyDescription in entity.properties {
            
            if propertyDescription is NSAttributeDescription {
                
                if propertyDescription.shouldExportAttribute() {
                    
                    let value = self.value(
                        for: propertyDescription as? NSAttributeDescription,
                        dateFormatter: dateFormatter,
                        relationshipType: relationshipType)
                    
                    if let value = value {
                        
                        let remoteKey = self.remoteKey(
                            for: propertyDescription as? NSAttributeDescription,
                            using: relationshipType,
                            inflectionType: inflectionType)

                        var currentObj = managedObjectAttributes
                        let split = remoteKey?.components(separatedBy: ".")
                        let range = NSRange(location: 0, length: split?.count ?? 0 - 1)
                        
                        if let components = (split as NSArray?)?.subarray(with: range) {
                            for key in components {
                                guard let key = key as? String else {
                                    continue
                                }
                                let currentValue = currentObj[key]
                                if currentValue == nil {
                                    currentObj[key] = [AnyHashable : Any]()
                                }
                                if currentObj[key] != nil {
                                    if let aCurrentObj = currentObj[key] as? [AnyHashable : Any] {
                                        currentObj = aCurrentObj
                                    }
                                }
                            }
                        }

                        let lastKey = split?.last
                        currentObj[lastKey] = value
                    }
                }
                
            } else if (propertyDescription is NSRelationshipDescription) && relationshipType != .none {
                
                if let relationshipDescription = propertyDescription as? NSRelationshipDescription {
                    
                    if relationshipDescription.shouldExportAttribute() {
                        
                        let isValidRelationship = !(parent != nil && (parent?.entity == relationshipDescription.destinationEntity) && !relationshipDescription.isToMany)
                        
                        if isValidRelationship {
                            let relationshipName = relationshipDescription.name
                            let relationships = self.value(forKey: relationshipName)
                            if let relationships = relationships {
                                let isToOneRelationship = !(relationships is Set<AnyHashable>) && !(relationships is NSOrderedSet)
                                if isToOneRelationship {
                                    var attributesForToOneRelationship: [AnyHashable : Any] = [:]
                                    if let relationships = relationships as? NSManagedObject {
                                        attributesForToOneRelationship = attributesFor(
                                            toOneRelationship: relationships,
                                            relationshipName: relationshipName,
                                            using: relationshipType,
                                            parent: self,
                                            dateFormatter: dateFormatter,
                                            inflectionType: inflectionType)
                                    }
                                    
                                    for (k, v) in attributesForToOneRelationship { managedObjectAttributes[k] = v }
                                    
                                } else {
                                    var attributesForToManyRelationship: [AnyHashable : Any] = [:]
                                    if let relationships = relationships as? Set<AnyHashable> {
                                        attributesForToManyRelationship = attributesFor(
                                            toManyRelationship: relationships,
                                            relationshipName: relationshipName,
                                            using: relationshipType,
                                            parent: self,
                                            dateFormatter: dateFormatter,
                                            inflectionType: inflectionType)
                                    }
                                    for (k, v) in attributesForToManyRelationship { managedObjectAttributes[k] = v }
                                }
                            }
                        }
                    }
                }
                              
            }
        }

        return managedObjectAttributes as? [String : Any?] ?? [:]
    }

    func attributesFor(
        toOneRelationship relationship: NSManagedObject,
        relationshipName: String,
        using relationshipType: SyncPropertyMapperRelationshipType,
        parent: NSManagedObject,
        dateFormatter: DateFormatter,
        inflectionType: SyncPropertyMapperInflectionType
    ) -> [AnyHashable : Any] {

        var attributesForToOneRelationship: [AnyHashable : Any] = [:]
        let attributes = relationship.hyp_dictionary(
            with: dateFormatter,
            parent: parent,
            using: inflectionType,
            andRelationshipType: relationshipType)
        if attributes.count > 0 {
            var key: String?
            switch inflectionType {
            case .snakeCase:
                key = relationshipName.camelCaseToSnakeCase()
            case .camelCase:
                key = relationshipName
            }
            if relationshipType == .nested {
                switch inflectionType {
                case .snakeCase:
                    key = "\(key ?? "")_\(PropertyMapperNestedAttributesKey)"
                case .camelCase:
                    key = "\(key ?? "")\(PropertyMapperNestedAttributesKey.capitalized)"
                }
            }

            attributesForToOneRelationship[key ?? ""] = attributes
        }

        return attributesForToOneRelationship
    }

    func attributesFor(
        toManyRelationship relationships: Set<AnyHashable>,
        relationshipName: String,
        using relationshipType: SyncPropertyMapperRelationshipType,
        parent: NSManagedObject,
        dateFormatter: DateFormatter,
        inflectionType: SyncPropertyMapperInflectionType
    ) -> [AnyHashable : Any] {

        var attributesForToManyRelationship: [AnyHashable : Any] = [:]
        var relationIndex = 0
        var relationsDictionary: [AnyHashable : Any] = [:]
        var relationsArray: [Any] = []
        for relationship in relationships {
            guard let relationship = relationship as? NSManagedObject else {
                continue
            }
            let attributes = relationship.hyp_dictionary(
                with: dateFormatter,
                parent: parent,
                using: inflectionType,
                andRelationshipType: relationshipType)
            if attributes.count > 0 {
                if relationshipType == .array {
                    relationsArray.append(attributes)
                } else if relationshipType == .nested {
                    let relationIndexString = String(format: "%lu", UInt(relationIndex))
                    relationsDictionary[relationIndexString] = attributes
                    relationIndex += 1
                }
            }
        }

        var key: String?
        switch inflectionType {
        case .snakeCase:
            key = relationshipName.camelCaseToSnakeCase()
        case .camelCase:
            key = relationshipName.camelized
        }
        if relationshipType == .array {
            attributesForToManyRelationship[key ?? ""] = relationsArray
        } else if relationshipType == .nested {
            let nestedAttributesPrefix = "\(key ?? "")_\(PropertyMapperNestedAttributesKey)"
            attributesForToManyRelationship[nestedAttributesPrefix] = relationsDictionary
        }

        return attributesForToManyRelationship
    }

    // MARK: - Private

    static let defaultDate_dateFormatter: DateFormatter? = nil

    func defaultDateFormatter() -> DateFormatter {
        if NSManagedObject.defaultDate_dateFormatter == nil {
            return DateFormatter()
        } else {
            return NSManagedObject.defaultDate_dateFormatter!
        }
    }
}

