//
//  NSDate+PropertyMapper.swift
//  Project
//
//  Created by Ivan Ricardo Espitia  on 16/03/22.
//

//  Converted to Swift 5.5 by Swiftify v5.5.24623 - https://swiftify.com/
import Foundation

private let DateParserDateNoTimestampFormat = "YYYY-MM-DD"
private let DateParserTimestamp = "T00:00:00+00:00"
private let DateParserDescriptionDate = "0000-00-00 00:00:00"
/// The type of date.
/// - iso8601:       International date standard.
/// - unixTimestamp: Number of seconds since Thursday, 1 January 1970.
enum DateType : Int {
    case iso8601
    case unixTimestamp
}

extension Date {
    
    
    public init(fromDateString dateString: String) {
        let dateType = dateString.dateType()
        switch dateType {
        case .iso8601:
            self.init(fromISO8601String: dateString)
        case .unixTimestamp:
            self.init(fromUnixTimestampString: dateString)        
        }
    }

    /// Converts the provided ISO 8601 string representation into a NSDate object. The ISO string can have the structure of any of the following values:
    /// @code
    /// 2014-01-02
    /// 2016-01-09T00:00:00
    /// 2014-03-30T09:13:00Z
    /// 2016-01-09T00:00:00.00
    /// 2015-06-23T19:04:19.911Z
    /// 2014-01-01T00:00:00+00:00
    /// 2015-09-10T00:00:00.184968Z
    /// 2015-09-10T00:00:00.116+0000
    /// 2015-06-23T14:40:08.000+02:00
    /// 2014-01-02T00:00:00.000000+00:00
    /// @endcode
    /// - Parameter iso8601: The ISO 8601 date as NSString.
    /// - Returns: The parsed date.
    public init(fromISO8601String dateString: String) {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            self.init(timeIntervalSince1970: date.timeIntervalSince1970)
        } else {
            self.init()
        }
    }
    
    /// Converts the provided Unix timestamp into a NSDate object.
    /// - Parameter unixTimestamp: The Unix timestamp to be used, also known as Epoch time. This value shouldn't be more than NSIntegerMax (2,147,483,647).
    /// - Returns: The parsed date.
    public init(fromUnixTimestampNumber unixTimestamp: NSNumber) {
        self.init(fromUnixTimestampString: unixTimestamp.stringValue)
    }

    /// Converts the provided Unix timestamp into a NSDate object.
    /// - Parameter unixTimestamp: The Unix timestamp to be used, also known as Epoch time. This value shouldn't be more than NSIntegerMax (2,147,483,647).
    /// - Returns: The parsed date.
    public init(fromUnixTimestampString unixTimestamp: String) {
        var parsedString = unixTimestamp

        let validUnixTimestamp = "1441843200"
        let validLength = validUnixTimestamp.count
        if unixTimestamp.count > validLength {
            parsedString = (unixTimestamp as NSString).substring(to: validLength)
        }

        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let unixTimestampNumber = numberFormatter.number(from: parsedString)
        self.init(timeIntervalSince1970: TimeInterval(unixTimestampNumber?.doubleValue ?? 0.0))
    }
}

/// String extension to check wethere a string represents a ISO 8601 date or a Unix timestamp one.
extension String {
    func dateType() -> DateType {
        if contains("-") {
            return .iso8601
        } else {
            return .unixTimestamp
        }
    }
}

