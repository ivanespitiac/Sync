//
//  Logger.swift
//  iOSTests
//
//  Created by Ivan Ricardo Espitia  on 17/03/22.
//

import Foundation

/*
 Log level definition for different types
 date: 15-12-2021
 */
enum LEVEL {
    case INFO
    case DEBUG
    case ERROR
}

/**
 Log class for control all print in the project enabling or disabling visibility of them
 date: 15-12-2021
 */
public class Logger {
    
    private init() {}
    
    static func logDebug(with value: String?) {
        log(with: LEVEL.DEBUG, with: value)
    }
    
    static func logInfo(with value: String?) {
        log(with: LEVEL.INFO, with: value)
    }
    
    static func logError(with value: String?) {
        log(with: LEVEL.ERROR, with: value)
    }
    
    private static func log(with level: LEVEL, with value: String?) {
    #if DEBUG
        switch level {
        case .INFO:
            print("Info: \(value ?? "")")
        case .DEBUG:
            print("Debug: \(value ?? "")")
        case .ERROR:
            print("Error: \(value ?? "")")
        }
    #else
    #endif
    }
    
    
}
