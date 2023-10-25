//  Logging.swift
//  Created by Andrew Ash on 10/24/23.

import Foundation

/// A type that implements the logging API required by this package
public protocol AsyncBluetoothLogging {
    func debug(_ message: String, error: Error?, file: StaticString, function: StaticString, line: Int)
    func info(_ message: String, error: Error?, file: StaticString, function: StaticString, line: Int)
    func error(_ message: String, error: Error?, file: StaticString, function: StaticString, line: Int)
    func warning(_ message: String, error: Error?, file: StaticString, function: StaticString, line: Int)
    func critical(_ message: String, error: Error?, file: StaticString, function: StaticString, line: Int)
}

/// Adds support for default values for protocol function parameters
extension AsyncBluetoothLogging {
    func debug(_ message: String,
               error: Error? = nil,
               file: StaticString = #file,
               function: StaticString = #function,
               line: Int = #line) {
        debug(message, error: error, file: file, function: function, line: line)
    }

    func info(_ message: String,
              error: Error? = nil,
              file: StaticString = #file,
              function: StaticString = #function,
              line: Int = #line) {
        info(message, error: error, file: file, function: function, line: line)
    }

    func warning(_ message: String,
              error: Error? = nil,
              file: StaticString = #file,
              function: StaticString = #function,
              line: Int = #line) {
        warning(message, error: error, file: file, function: function, line: line)
    }

    func error(_ message: String,
               error: Error? = nil,
               file: StaticString = #file,
               function: StaticString = #function,
               line: Int = #line) {
        self.error(message, error: error, file: file, function: function, line: line)
    }

    func critical(_ message: String, 
                  error: Error? = nil,
                  file: StaticString = #file,
                  function: StaticString = #function,
                  line: Int = #line) {
        critical(message, error: error, file: file, function: function, line: line)
    }
}
