//
//  NSManagedObject+PropertyMapperHelpers.swift
//  Project
//
//  Created by Ivan Ricardo Espitia  on 16/03/22.
//

//  Converted to Swift 5.5 by Swiftify v5.5.24623 - https://swiftify.com/
import CoreData

/// Internal helpers, not meant to be included in the public APIs.
private let PropertyMapperDestroyKey = "destroy"

extension NSManagedObject {
    
    func value(
        for attributeDescription: NSAttributeDescription?,
        dateFormatter: DateFormatter?,
        relationshipType: SyncPropertyMapperRelationshipType) -> Any? {
            
        var result: Any?
            
        if attributeDescription?.attributeType != .transformableAttributeType {
            
            let value = self.value(forKey: attributeDescription?.name ?? "")
            let nilOrNullValue = value == nil || value is NSNull
            let customTransformerName = attributeDescription?.customTransformerName()
            
            if nilOrNullValue {
                result = NSNull()
            } else if value is Date {
                if let valueAux = value as? Date {
                    result = dateFormatter?.string(from: valueAux)
                }
            } else if value is UUID {
                result = (value as? UUID)?.uuidString
            } else if value is NSURL {
                result = (value as? NSURL)?.absoluteString
            } else if let customTransformerName = customTransformerName {
                let transformer = ValueTransformer(forName: NSValueTransformerName(customTransformerName))
                if let transformer = transformer {
                    result = transformer.reverseTransformedValue(value)
                }
            }
        }

        return result
    }

    func attributeDescription(forRemoteKey remoteKey: String?) -> NSAttributeDescription? {
        return attributeDescription(forRemoteKey: remoteKey, using: .snakeCase)
    }

    func attributeDescription(
        forRemoteKey remoteKey: String?,
        using inflectionType: SyncPropertyMapperInflectionType
    ) -> NSAttributeDescription? {
        
        var foundAttributeDescription: NSAttributeDescription?

        for (_, propertyDescription) in entity.properties.enumerated() {
            if propertyDescription is NSAttributeDescription {
                let attributeDescription = propertyDescription as? NSAttributeDescription

                let customRemoteKey = entity.propertiesByName[attributeDescription?.name ?? ""]?.customKey()

                let currentAttributeHasTheSameRemoteKey = (customRemoteKey?.count ?? 0) > 0 && (customRemoteKey == remoteKey)
                if currentAttributeHasTheSameRemoteKey {
                    foundAttributeDescription = attributeDescription
                }

                let customRootRemoteKey = customRemoteKey?.components(separatedBy: ".").first
                let currentAttributeHasTheSameRootRemoteKey = (customRootRemoteKey?.count ?? 0) > 0 && (customRootRemoteKey == remoteKey)
                if currentAttributeHasTheSameRootRemoteKey {
                    foundAttributeDescription = attributeDescription
                }

                if attributeDescription?.name == remoteKey {
                    foundAttributeDescription = attributeDescription
                }

                var localKey = remoteKey?.camelized
                let isReservedKey = (NSManagedObject.reservedAttributes()?.contains(remoteKey ?? "")) ?? false
                if isReservedKey {
                    let prefixedRemoteKey = prefixedAttribute(remoteKey, using: inflectionType)
                    localKey = prefixedRemoteKey?.camelized
                }

                if attributeDescription?.name == localKey {
                    foundAttributeDescription = attributeDescription
                }
            }
        }
        
        if foundAttributeDescription == nil {
            
            for (_, propertyDescription) in entity.properties.enumerated() {
                if propertyDescription is NSAttributeDescription {
                    let attributeDescription = propertyDescription as? NSAttributeDescription

                    if (remoteKey == SyncDefaultRemotePrimaryKey) && ((attributeDescription?.name == SyncDefaultLocalPrimaryKey) || (attributeDescription?.name == SyncDefaultLocalCompatiblePrimaryKey)) {
                        foundAttributeDescription = entity.propertiesByName[attributeDescription?.name ?? ""] as? NSAttributeDescription
                    }

                }
            }
            
        }

        return foundAttributeDescription
    }

    func attributeDescriptions(forRemoteKeyPath remoteKey: String?) -> [AnyHashable]? {
        var foundAttributeDescriptions: [AnyHashable] = []
        
        for (_, propertyDescription) in entity.properties.enumerated() {
            if propertyDescription is NSAttributeDescription {
                let attributeDescription = propertyDescription as? NSAttributeDescription

                let customRemoteKeyPath = entity.propertiesByName[attributeDescription?.name ?? ""]?.customKey()
                let customRootRemoteKey = customRemoteKeyPath?.components(separatedBy: ".").first
                let rootRemoteKey = remoteKey?.components(separatedBy: ".").first
                let currentAttributeHasTheSameRootRemoteKey = (customRootRemoteKey?.count ?? 0) > 0 && (customRootRemoteKey == rootRemoteKey)
                if currentAttributeHasTheSameRootRemoteKey {
                    if let attributeDescription = attributeDescription {
                        foundAttributeDescriptions.append(attributeDescription)
                    }
                }
            }
        }
        
        return foundAttributeDescriptions
    }

    func remoteKey(for attributeDescription: NSAttributeDescription?) -> String? {
        return remoteKey(for: attributeDescription, using: .nested, inflectionType: .snakeCase)
    }

    func remoteKey(
        for attributeDescription: NSAttributeDescription?,
        inflectionType: SyncPropertyMapperInflectionType
    ) -> String? {
        return remoteKey(for: attributeDescription, using: .nested, inflectionType: inflectionType)
    }

    func remoteKey(
        for attributeDescription: NSAttributeDescription?,
        using relationshipType: SyncPropertyMapperRelationshipType
    ) -> String? {
        return remoteKey(for: attributeDescription, using: relationshipType, inflectionType: .snakeCase)
    }

    func remoteKey(
        for attributeDescription: NSAttributeDescription?,
        using relationshipType: SyncPropertyMapperRelationshipType,
        inflectionType: SyncPropertyMapperInflectionType
    ) -> String? {
        let localKey = attributeDescription?.name
        var remoteKey: String?

        let customRemoteKey = attributeDescription?.customKey()
        if let customRemoteKey = customRemoteKey {
            remoteKey = customRemoteKey
        } else if (localKey == SyncDefaultLocalPrimaryKey) || (localKey == SyncDefaultLocalCompatiblePrimaryKey) {
            remoteKey = SyncDefaultRemotePrimaryKey
        } else if (localKey == PropertyMapperDestroyKey) && relationshipType == .nested {
            remoteKey = "_\(PropertyMapperDestroyKey)"
        } else {
            switch inflectionType {
            case .snakeCase:
                remoteKey = localKey?.camelCaseToSnakeCase()
            case .camelCase:
                remoteKey = localKey            
            }
        }

        let isReservedKey = (reservedKeys(using: inflectionType)?.contains(remoteKey ?? "")) ?? false
        if isReservedKey {
            var prefixedKey = remoteKey
            if let subRange = Range<String.Index>(NSRange(location: 0, length: prefixedKey?.count ?? 0), in: prefixedKey ?? "") { prefixedKey = prefixedKey?.replacingOccurrences(of: remotePrefix(using: inflectionType) ?? "", with: "", options: .caseInsensitive, range: subRange) }
            remoteKey = prefixedKey
            if inflectionType == .camelCase {
                remoteKey = remoteKey?.camelized
            }
        }

        return remoteKey
    }

    func value(
        for attributeDescription: NSAttributeDescription?,
        usingRemoteValue remoteValue: Any?
    ) -> Any? {
        
        var value: Any?
                        
        let attributedClass: AnyClass? = NSClassFromString(attributeDescription?.attributeValueClassName ?? "")
                        
        if remoteValue is String || remoteValue is NSNumber || remoteValue is NSString {
            value = remoteValue
        }

        let customTransformerName = attributeDescription?.customTransformerName()
        if let customTransformerName = customTransformerName {
            let transformer = ValueTransformer(forName: NSValueTransformerName(customTransformerName))
            if let transformer = transformer {
                value = transformer.transformedValue(remoteValue)
            }
        }

        let stringValueAndNumberAttribute = (remoteValue is NSString) && attributedClass == NSNumber.self

        let numberValueAndStringAttribute = (remoteValue is NSNumber) && attributedClass == NSString.self

        let stringValueAndDateAttribute = (remoteValue is NSString) && attributedClass == Date.self

        let numberValueAndDateAttribute = (remoteValue is NSNumber) && attributedClass == Date.self

        let stringValueAndUUIDAttribute = (remoteValue is NSString) && attributedClass == UUID.self

        let stringValueAndURIAttribute = (remoteValue is NSString) && attributedClass == NSURL.self

        let dataAttribute = attributedClass == Data.self

        let numberValueAndDecimalAttribute = (remoteValue is NSNumber) && attributedClass == NSDecimalNumber.self

        let stringValueAndDecimalAttribute = (remoteValue is NSString) && attributedClass == NSDecimalNumber.self

        let transformableAttribute = attributedClass == nil && attributeDescription?.valueTransformerName != nil && value == nil

        if stringValueAndNumberAttribute {
            let formatter = NumberFormatter()
            formatter.locale = NSLocale(localeIdentifier: "en_US") as Locale
            value = formatter.number(from: remoteValue as? String ?? "")
        } else if numberValueAndStringAttribute {
            if let remoteValue = remoteValue {
                value = "\(remoteValue)"
            }
        } else if stringValueAndDateAttribute {
            value = Date(fromDateString: remoteValue as? String ?? "")
        } else if numberValueAndDateAttribute {
            value = Date(fromUnixTimestampNumber: remoteValue as? NSNumber ?? 0)
        } else if stringValueAndUUIDAttribute {
            value = UUID(uuidString: remoteValue as? String ?? "")
        } else if stringValueAndURIAttribute {
            value = URL(string: remoteValue as? String ?? "")
        } else if dataAttribute {
            do {
                if let remoteValue = remoteValue {
                    value = try NSKeyedArchiver.archivedData(withRootObject: remoteValue, requiringSecureCoding: false)
                }
            } catch {
            }
        } else if numberValueAndDecimalAttribute {
            let number = remoteValue as? NSNumber
            if let decimalValue = number?.decimalValue {
                value = NSDecimalNumber(decimal: decimalValue)
            }
        } else if stringValueAndDecimalAttribute {
            value = NSDecimalNumber(string: remoteValue as? String)
        } else if transformableAttribute {
            let transformer = ValueTransformer(forName: NSValueTransformerName(attributeDescription?.valueTransformerName ?? ""))
            if let transformer = transformer {
                let newValue = transformer.transformedValue(remoteValue)
                if let newValue = newValue {
                    value = newValue
                }
            }
        }                
        
        return value
    }

    func remotePrefix(using inflectionType: SyncPropertyMapperInflectionType) -> String? {
        switch inflectionType {
        case .snakeCase:
            if let hyp_snakeCase = entity.name?.camelCaseToSnakeCase() {
                return "\(hyp_snakeCase)_"
            }
            return nil
        case .camelCase:
            return entity.name?.camelized
        }
    }

    func prefixedAttribute(_ attribute: String?, using inflectionType: SyncPropertyMapperInflectionType) -> String? {
        let remotePrefix = self.remotePrefix(using: inflectionType)

        switch inflectionType {
        case .snakeCase:
            return "\(remotePrefix ?? "")\(attribute ?? "")"
        case .camelCase:
            return "\(remotePrefix ?? "")\(attribute?.capitalized ?? "")"
        }
    }

    func reservedKeys(using inflectionType: SyncPropertyMapperInflectionType) -> [AnyHashable]? {
        var keys: [AnyHashable] = []
        let reservedAttributes = NSManagedObject.reservedAttributes()

        for attribute in reservedAttributes ?? [] {
            guard let attribute = attribute as? String else {
                continue
            }
            keys.append(prefixedAttribute(attribute, using: inflectionType) ?? "")
        }

        return keys
    }

    class func reservedAttributes() -> [AnyHashable]? {
        return ["type", "description", "signed"]
    }
}

