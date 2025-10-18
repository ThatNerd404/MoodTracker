//
//  SecondViewController.swift
//  MoodTracker
//
//  Created by Code Academy on 1/6/25.
//

import UIKit
import FirebaseFirestore

class SecondViewController: UIViewController {
    
    // Firebase Firestore reference
    private let db = Firestore.firestore()
    
    @IBOutlet weak var infoBox: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the info box
        setupInfoBox()
        
        // Load and display mood statistics
        loadMoodStatistics()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Refresh data every time the view appears
        loadMoodStatistics()
    }
    
    private func setupInfoBox() {
        infoBox.numberOfLines = 0
        infoBox.textAlignment = .left
        infoBox.font = UIFont.systemFont(ofSize: 16)
        infoBox.text = "Loading mood statistics..."
    }
    
    // MARK: - Firebase Functions
    
    private func loadMoodStatistics() {
        // Query mood entries from Firebase
        db.collection("mood_entries").getDocuments { [weak self] (querySnapshot, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error getting mood entries: \(error.localizedDescription)")
                    self?.displayError()
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    self?.displayNoData()
                    return
                }
                
                self?.processMoodData(documents)
            }
        }
    }
    
    private func processMoodData(_ documents: [QueryDocumentSnapshot]) {
        var moodCounts: [String: Int] = [:]
        var totalEntries = 0
        var todayEntries = 0
        var uniqueStudents = Set<String>()
        
        let calendar = Calendar.current
        let today = Date()
        
        for document in documents {
            let data = document.data()
            
            // Get mood type
            if let mood = data["mood"] as? String {
                moodCounts[mood, default: 0] += 1
                totalEntries += 1
                
                // Track unique students (background only)
                if let studentId = data["studentId"] as? String {
                    uniqueStudents.insert(studentId)
                }
                
                // Check if entry is from today
                if let timestamp = data["timestamp"] as? Timestamp {
                    let entryDate = timestamp.dateValue()
                    if calendar.isDate(entryDate, inSameDayAs: today) {
                        todayEntries += 1
                    }
                }
            }
        }
        
        displayStatistics(moodCounts: moodCounts, totalEntries: totalEntries, todayEntries: todayEntries, activeStudentCount: uniqueStudents.count)
    }
    
    private func displayStatistics(moodCounts: [String: Int], totalEntries: Int, todayEntries: Int, activeStudentCount: Int) {
        var statisticsText = "📊 Mood Statistics\n\n"
        
        // General participation info
        statisticsText += "📅 Today: \(todayEntries) mood check-ins\n"
        statisticsText += "📈 Total: \(totalEntries) mood check-ins\n"
        statisticsText += "👥 Active Users: \(activeStudentCount)\n\n"
        
        if !moodCounts.isEmpty {
            statisticsText += "🎭 Mood Breakdown:\n"
            
            // Sort moods by count (highest first)
            let sortedMoods = moodCounts.sorted { $0.value > $1.value }
            
            for (mood, count) in sortedMoods {
                let emoji = emojiForMood(mood)
                let percentage = totalEntries > 0 ? (Double(count) / Double(totalEntries) * 100) : 0
                statisticsText += "\(emoji) \(mood.capitalized): \(count) (\(String(format: "%.1f", percentage))%)\n"
            }
            
            // Find most common mood
            if let mostCommonMood = sortedMoods.first {
                statisticsText += "\n🏆 Most common mood: \(mostCommonMood.key.capitalized)"
            }
            
            // Activity insights
            let avgDaily = todayEntries > 0 ? Double(totalEntries) / 7.0 : 0
            if avgDaily > 0 {
                statisticsText += "\n💡 Weekly average: \(String(format: "%.1f", avgDaily)) entries per day"
            }
            
            if todayEntries > 5 {
                statisticsText += "\n✅ Great participation today!"
            } else if todayEntries == 0 {
                statisticsText += "\n📢 No check-ins today yet"
            }
        } else {
            statisticsText += "No mood data available yet.\nStart tracking your moods!"
        }
        
        infoBox.text = statisticsText
    }
    
    private func emojiForMood(_ mood: String) -> String {
        switch mood.lowercased() {
        case "happy": return "😊"
        case "sarcastic": return "😏"
        case "love": return "😍"
        case "angry": return "😠"
        case "party": return "🥳"
        case "sleepy": return "😴"
        case "upset": return "😢"
        case "scared": return "😨"
        case "cry": return "😭"
        default: return "🎭"
        }
    }
    
    private func displayError() {
        infoBox.text = """
        ❌ Error Loading Data
        
        Unable to load mood statistics from the database.
        
        Please check your internet connection and try again.
        """
    }
    
    private func displayNoData() {
        infoBox.text = """
        📱 Welcome to MoodTracker!
        
        No mood entries found yet.
        
        Go back to the main screen and start tracking your moods to see statistics here.
        
        Your data will be automatically saved and displayed here.
        """
    }
    
    // MARK: - Additional Features
    
    // You can add a refresh button action
    @IBAction func refreshButtonPressed(_ sender: Any) {
        loadMoodStatistics()
    }
    
    // You can add a clear data button (for testing)
    @IBAction func clearDataButtonPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Clear All Data",
                                    message: "Are you sure you want to delete all mood entries? This cannot be undone.",
                                    preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete All", style: .destructive) { [weak self] _ in
            self?.clearAllMoodData()
        })
        
        present(alert, animated: true)
    }
    
    private func clearAllMoodData() {
        db.collection("mood_entries").getDocuments { [weak self] (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else { return }
            
            let batch = self?.db.batch()
            
            for document in documents {
                batch?.deleteDocument(document.reference)
            }
            
            batch?.commit { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error clearing data: \(error.localizedDescription)")
                    } else {
                        print("All mood data cleared successfully")
                        self?.loadMoodStatistics() // Refresh display
                    }
                }
            }
        }
    }
}
