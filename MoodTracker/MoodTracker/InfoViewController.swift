//
//  InfoViewController.swift
//  MoodTracker - Firebase Version
//

import UIKit
import FirebaseFirestore

class InfoViewController: UIViewController {
    
    // Firebase Firestore reference
    private let db = Firestore.firestore()
    
    // MARK: - IBOutlets
    // Connect these to your "*Data Table Here*" labels in storyboard
    @IBOutlet weak var siteIdentifierLabel: UILabel!      // Left screen data label
    @IBOutlet weak var moodTrackerLabel: UILabel!         // Right screen data label
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Debug: Test outlet connections
        print("🔍 Testing outlet connections...")
        print("siteIdentifierLabel: \(siteIdentifierLabel != nil ? "✅ Connected" : "❌ Not connected")")
        print("moodTrackerLabel: \(moodTrackerLabel != nil ? "✅ Connected" : "❌ Not connected")")
        
        setupLabels()
        loadFirebaseData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadFirebaseData() // Refresh data when screen appears
    }
    
    private func setupLabels() {
        // Setup Site Identifier label (left screen)
        guard let siteIdentifierLabel = siteIdentifierLabel else {
            print("❌ siteIdentifierLabel outlet not connected!")
            return
        }
        siteIdentifierLabel.numberOfLines = 0
        siteIdentifierLabel.textAlignment = .left
        siteIdentifierLabel.font = UIFont.systemFont(ofSize: 50, weight: .regular)
       
        // Setup Mood Tracker label (right screen)
        guard let moodTrackerLabel = moodTrackerLabel else {
            print("❌ moodTrackerLabel outlet not connected!")
            return
        }
        moodTrackerLabel.numberOfLines = 0
        moodTrackerLabel.textAlignment = .left
        moodTrackerLabel.font = UIFont.systemFont(ofSize: 30, weight: .medium) // Clean system font
       
        // Initial loading text
        siteIdentifierLabel.text = "Loading data from Firebase..."
        moodTrackerLabel.text = "Loading analytics from Firebase..."
    }
    
    // MARK: - Firebase Data Loading
    private func loadFirebaseData() {
        print("🔥 Loading mood data from Firebase...")
        
        // Query mood entries from Firebase
        db.collection("mood_entries")
            .order(by: "timestamp", descending: true)
            .getDocuments { [weak self] (querySnapshot, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Error getting mood entries: \(error.localizedDescription)")
                        self?.displayError(error: error)
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        print("📝 No documents found in Firebase")
                        self?.displayNoData()
                        return
                    }
                    
                    print("✅ Found \(documents.count) mood entries in Firebase")
                    
                    // Convert Firebase documents to mood data (studentId tracked in background)
                    var moodEntries: [(mood: String, timestamp: Date, studentId: String)] = []
                    
                    for document in documents {
                        let data = document.data()
                        if let mood = data["mood"] as? String,
                           let timestamp = data["timestamp"] as? Timestamp {
                            
                            let studentId = data["studentId"] as? String ?? "unknown"
                            moodEntries.append((mood: mood, timestamp: timestamp.dateValue(), studentId: studentId))
                        }
                    }
                    
                    if moodEntries.isEmpty {
                        self?.displayNoData()
                    } else {
                        self?.displaySiteIdentifierData(entries: moodEntries)
                        self?.displayMoodTrackerAnalytics(entries: moodEntries)
                    }
                }
            }
    }
    
    // MARK: - Site Identifier Information (Left Screen)
    private func displaySiteIdentifierData(entries: [(mood: String, timestamp: Date, studentId: String)]) {
        guard let siteIdentifierLabel = siteIdentifierLabel else {
            print("❌ siteIdentifierLabel outlet not connected!")
            return
        }
       
        var dataText = "       📊 FIREBASE MOOD DATA\n"
        dataText += "━━━━━━━━━━━━━━━━\n\n"
        
    
        siteIdentifierLabel.text = dataText
    }
    
    // MARK: - Mood Tracker Analytics (Right Screen)
    private func displayMoodTrackerAnalytics(entries: [(mood: String, timestamp: Date, studentId: String)]) {
        // Safety check - prevent crash if outlet not connected
        guard let moodTrackerLabel = moodTrackerLabel else {
            print("❌ moodTrackerLabel outlet not connected!")
            return
        }
        
        var analyticsText = ""
       
        // Calculate mood counts
        var moodCounts: [String: Int] = [:]
        var totalEntries = entries.count
        
        for entry in entries {
            moodCounts[entry.mood, default: 0] += 1
        }
        
        // Define all 9 moods in order
        let allMoods = ["happy", "sarcastic", "love", "angry", "party", "sleepy", "upset", "scared", "cry"]
        
        analyticsText += "🎭 EMOJI TOTALS\n\n"
        
        // Clean, simple formatting - no table alignment
        for mood in allMoods {
            let count = moodCounts[mood, default: 0]
            let emoji = emojiForMood(mood)
            let percentage = totalEntries > 0 ? (Double(count) / Double(totalEntries) * 100) : 0
            
            analyticsText += "\(emoji) \(mood.capitalized): \(count) (\(Int(percentage))%)\n"
        }
       
        analyticsText += "\n" + String(repeating: "─", count: 27) + "\n"
        analyticsText += "📊TOTAL SUBMISSIONS: \(totalEntries) submissions\n\n"
        
        // Find top mood
        if let topMood = moodCounts.max(by: { $0.value < $1.value }) {
            let topEmoji = emojiForMood(topMood.key)
            analyticsText += "🏆 Most Popular\n"
            analyticsText += "\(topEmoji) \(topMood.key.capitalized) - \(topMood.value) times\n\n"
        }
        
        // Find least mood (if any entries exist)
        if totalEntries > 0, let leastMood = moodCounts.filter({ $0.value > 0 }).min(by: { $0.value < $1.value }) {
            let leastEmoji = emojiForMood(leastMood.key)
            analyticsText += "📉 Least Used\n"
            analyticsText += "\(leastEmoji) \(leastMood.key.capitalized) - \(leastMood.value) times\n\n"
        }
        
        
        moodTrackerLabel.text = analyticsText
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
    
    private func timeAgoString(from date: Date) -> String {
        let timeInterval = Date().timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        }
    }
    
    private func displayError(error: Error) {
        siteIdentifierLabel?.text = """
        ❌ Firebase Connection Error
        
        \(error.localizedDescription)
        
        Check your internet connection and Firebase setup.
        """
        
        moodTrackerLabel?.text = """
        ❌ Firebase Connection Error
        
        Unable to load analytics from Firebase.
        
        • Check internet connection
        • Verify Firebase setup
        • Try refreshing the screen
        
        Error: \(error.localizedDescription)
        """
    }
    
    private func displayNoData() {
        siteIdentifierLabel?.text = """
        📊 FIREBASE MOOD DATA
        ━━━━━━━━━━━━━━━━━━━━━━━━━
        
        🏫 SITE INFORMATION:
        School: Your School Name
        Class: Current Class
        
        📝 STATUS:
        No mood entries in Firebase yet.
        
        Students need to check in
        with their moods first.
        
        🔥 Connected to Firebase Cloud
        """
        
        moodTrackerLabel?.text = """
        📊 MOOD TRACKER TOTALS
        ━━━━━━━━━━━━━━━━━━━━━━━━━
        
        🎭 EMOJI PRESS TOTALS:
        
        😊 Happy      :   0 ( 0%)
        😏 Sarcastic  :   0 ( 0%)
        😍 Love       :   0 ( 0%)
        😠 Angry      :   0 ( 0%)
        🥳 Party      :   0 ( 0%)
        😴 Sleepy     :   0 ( 0%)
        😢 Upset      :   0 ( 0%)
        😨 Scared     :   0 ( 0%)
        😭 Cry        :   0 ( 0%)
        
        ━━━━━━━━━━━━━━━━━━━━━━━━━
        TOTAL SUBMISSIONS: 0
        
        🎯 Waiting for mood data...
        
        🔥 Firebase Database Ready!
        """
    }
    
    // MARK: - Actions
    @IBAction func refreshButtonPressed(_ sender: Any) {
        print("🔄 Refreshing Firebase data")
        loadFirebaseData()
    }
    
    @IBAction func logOutButtonPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Log Out",
                                    message: "Are you sure you want to log out?",
                                    preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { _ in
            // Navigate back to welcome screen
            self.navigationController?.popToRootViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
}

