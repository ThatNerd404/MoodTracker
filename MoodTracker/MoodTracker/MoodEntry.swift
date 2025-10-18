//
//  MoodEntry.swift
//  MoodTracker
//
//  Created by Code Academy on 1/15/25.
//

import Foundation

// MARK: - Data Model for Local Storage
struct MoodEntry: Codable {
    let mood: String
    let timestamp: Date
    let studentId: String?
    let siteID: String  // Add this line
    
    init(mood: String, studentId: String? = nil, siteID: String) {  // Update this line
        self.mood = mood
        self.timestamp = Date()
        self.studentId = studentId
        self.siteID = siteID  // Add this line
    }
}
