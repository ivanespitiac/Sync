//
//  Inflections.swift
//  Project
//
//  Created by Ivan Ricardo Espitia  on 16/03/22.
//

//  Converted to Swift 5.5 by Swiftify v5.5.24623 - https://swiftify.com/
import Foundation

typealias InflectionsStringStorageBlock = () -> Void

// Using for parsing camel case
fileprivate let badChars = CharacterSet.alphanumerics.inverted

extension String {
    
    /**
     Parse to snake case case words
     */
    func camelCaseToSnakeCase() -> String {
        let acronymPattern = "([A-Z]+)([A-Z][a-z]|[0-9])"
        let fullWordsPattern = "([a-z])([A-Z]|[0-9])"
        let digitsFirstPattern = "([0-9])([A-Z])"
        return self.processCamelCaseRegex(pattern: acronymPattern)?
          .processCamelCaseRegex(pattern: fullWordsPattern)?
          .processCamelCaseRegex(pattern:digitsFirstPattern)?.lowercased() ?? self.lowercased()
    }
    
    fileprivate func processCamelCaseRegex(pattern: String) -> String? {
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: count)
        return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2")
    }

    /**
     Parse to camel case words
     */
    
    var uppercasingFirst: String {
        return prefix(1).uppercased() + dropFirst()
    }

    var lowercasingFirst: String {
        return prefix(1).lowercased() + dropFirst()
    }

    var camelized: String {
        guard !isEmpty else {
            return ""
        }
        let parts = self.components(separatedBy: badChars)
        let first = String(describing: parts.first!).lowercasingFirst
        let rest = parts.dropFirst().map({String($0).uppercasingFirst})
        return ([first] + rest).joined(separator: "")
    }
    
    // -----------------------------------------------------------------------

    @available(*, deprecated, message: "Use instead 'camelCaseToSnakeCase()'")
    func hyp_snakeCase() -> String {
        
        let stringStorage = InflectionsStringStorage.sharedInstance()
        var storedResult: String? = nil

        stringStorage.perform(onDictionary: {
            storedResult = stringStorage.snakeCaseStorage[self] as? String
        })

        if let storedResult = storedResult {
            return storedResult
        } else {
            let firstLetterLowercase = self.hyp_lowerCaseFirstLetter()
            let result = firstLetterLowercase.hyp_replaceIdentifier(with: "_")

            stringStorage.perform(onDictionary: {
                stringStorage.snakeCaseStorage[self] = result
            })

            return result ?? ""
        }
    }

    @available(*, deprecated, message: "Use instead 'camelized'")
    func hyp_camelCase() -> String? {
        let stringStorage = InflectionsStringStorage.sharedInstance()
        var storedResult: String? = nil

        stringStorage.perform(onDictionary: {
            storedResult = stringStorage.camelCaseStorage[self] as? String
        })

        if let storedResult = storedResult {
            return storedResult
        } else {
            var result: String?

            if contains("_") {
                var processedString = self as String
                processedString = processedString.hyp_replaceIdentifier(with: "") ?? ""
                let remoteStringIsAnAcronym = String.acronyms().contains(processedString.lowercased())
                result = remoteStringIsAnAcronym ? processedString.lowercased() : processedString.hyp_lowerCaseFirstLetter()
            } else {
                result = hyp_lowerCaseFirstLetter()
            }

            stringStorage.perform(onDictionary: {
                stringStorage.camelCaseStorage[self] = result
            })

            return result
        }
    }

    func hyp_containsWord(_ word: String?) -> Bool {
        var found = false

        let components = self.components(separatedBy: "_")

        for component in components {
            if component == word {
                found = true
                break
            }
        }

        return found
    }

    func hyp_lowerCaseFirstLetter() -> String {
        var mutableString = self as String
        let firstLetter = (mutableString as NSString).substring(to: 1).lowercased()
        if let subRange = Range<String.Index>(NSRange(location: 0, length: 1), in: mutableString) { mutableString.replaceSubrange(subRange, with: firstLetter) }

        return mutableString
    }

    func hyp_replaceIdentifier(with replacementString: String?) -> String? {
        return ""
    }

    static func acronyms() -> [AnyHashable] {
        return ["uuid", "id", "pdf", "url", "png", "jpg", "uri", "json", "xml"]
    }
}

/**
 Inflections Store custom
 */
class InflectionsStringStorage: NSObject {
    
    var serialQueue: DispatchQueue?
    
    //private var _snakeCaseStorage: [AnyHashable : Any]?
    var snakeCaseStorage: [AnyHashable : Any] = [:]

    //private var _camelCaseStorage: [AnyHashable : Any]?
    var camelCaseStorage: [AnyHashable : Any] = [:]
    
    // Singleton
    private static var sharedInstanceVar: InflectionsStringStorage = {
        let store = InflectionsStringStorage()
        return store
    }()

    class func sharedInstance() -> InflectionsStringStorage {
        return sharedInstanceVar
    }

    override init() {
        super.init()
        serialQueue = DispatchQueue(label: "com.syncdb.NSString_Inflections.serialQueue")
    }

    func perform(onDictionary block: InflectionsStringStorageBlock) {
        serialQueue?.sync(execute: block)
    }
    
}
