//
//  ViewController.swift
//  SQLite Persistence
//
//  Created by Steve D'Amico on 3/18/16.
//  Copyright © 2016 Steve D'Amico. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet var lineFields:[UITextField]!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // Get path to database, returns file's path not its URL
        var database:COpaquePointer = nil
        // Use path to open or create (if it doesn't exist) the database
        var result = sqlite3_open(dataFilePath(), &database)
        if result != SQLITE_OK {
            sqlite3_close(database)
            print("Failed to open database")
            return
        }
        
        // If problem in opening database print an error message
        let createSQL = "CREATE TABLE IF NOT EXISTS FIELDS " + "(ROW INTEGER PRIMARY KEY, FIELD_DATA TEXT);"
        var errMsg:UnsafeMutablePointer<Int8> = nil
        result = sqlite3_exec(database, createSQL, nil, nil, &errMsg)
        if (result != SQLITE_OK) {
            sqlite3_close(database)
            print("Failed to create table")
            return
        }
        
        // Do we have a table to open
        let query = "SELECT ROW, FIELD_DATA FROM FIELDS ORDER BY ROW"
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {   // Orders the rows in which they were stored
                // Integer is the number of the row in the GUI
                let row = Int(sqlite3_column_int(statement, 0))
                let rowData = sqlite3_column_text(statement, 1)
                // String content of row
                let fieldValue = String.fromCString(UnsafePointer<CChar>(rowData))
                lineFields[row].text = fieldValue!
            }
            sqlite3_finalize(statement)
        }
        // Close database connection when finished creating or loading the table
        sqlite3_close(database)
        
        let app = UIApplication.sharedApplication()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "applicationWillResignActive:", name: UIApplicationWillResignActiveNotification, object: app)
    }
    
    // Save data when app is inactive
    func applicationWillResignActive(notification:NSNotification) {
        var database:COpaquePointer = nil
        let result = sqlite3_open(dataFilePath(), &database)
        if result != SQLITE_OK {
            sqlite3_close(database)
            print("Failed to open database")
            return
        }
        
        for var i = 0; i < lineFields.count; i++ {
            let field = lineFields[i]
            // Using INSERT OR REPLACE versus INSERT handles if a row does not exist
            let update = "INSERT OR REPLACE INTO FIELDS (ROW, FIELD_DATA) " + "VALUES (?, ?);"
            var statement:COpaquePointer = nil
            if sqlite3_prepare_v2(database, update, -1, &statement, nil) == SQLITE_OK {
                let text = field.text
                sqlite3_bind_int(statement, 1, Int32(i))
                sqlite3_bind_text(statement, 2, text!, -1, nil)
            }
            if sqlite3_step(statement) != SQLITE_DONE { // Executes update
                print("Error updating table")
                sqlite3_close(database)
                return
            }
            sqlite3_finalize(statement)
        }
        sqlite3_close(database)
    }
        
        func dataFilePath() -> String {
            let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
            return urls.first!.URLByAppendingPathComponent("data.plist").path!
        }
    }
        

