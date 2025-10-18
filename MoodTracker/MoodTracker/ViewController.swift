//
//  ViewController.swift
//  MoodTracker
//
//  Created by Code Academy on 1/2/25.
//

import UIKit
import FirebaseFirestore

class ViewController: UIViewController {
    
    // Firebase Firestore reference
    private let db = Firestore.firestore()
    
    // Auto-reset timer
    private var autoResetTimer: Timer?
    
    // Mood counters (keeping for local tracking)
    var happyCount = 0
    var sarcasticCount = 0
    var loveCount = 0
    var angryCount = 0
    var partyCount = 0
    var sleepyCount = 0
    var upsetCount = 0
    var scaredCount = 0
    var cryCount = 0
    
    // MARK: - IBOutlets (No reset button - using auto-reset)
    @IBOutlet weak var statusBox: UILabel!
    @IBOutlet weak var happyButton: UIButton!
    @IBOutlet weak var sarcasticButton: UIButton!
    @IBOutlet weak var loveButton: UIButton!
    @IBOutlet weak var angryButton: UIButton!
    @IBOutlet weak var partyButton: UIButton!
    @IBOutlet weak var sleepyButton: UIButton!
    @IBOutlet weak var upsetButton: UIButton!
    @IBOutlet weak var scaredButton: UIButton!
    @IBOutlet weak var cryButton: UIButton!
    @IBOutlet weak var informationButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup automatic student ID (background only)
        setupAutomaticStudentId()
        
        // Test Firebase connection on startup
        testFirebaseConnection()
    }
    
    // MARK: - Auto-Reset Timer Management
    private func startAutoResetTimer() {
        print("⏰ Starting auto-reset timer (3 seconds)")
        
        // Cancel any existing timer first
        cancelAutoResetTimer()
        
        // Start new timer for 3 seconds
        autoResetTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                print("⏰ Auto-reset timer triggered - returning to emoji selection")
                self?.performAutoReset()
            }
        }
    }
    
    private func cancelAutoResetTimer() {
        autoResetTimer?.invalidate()
        autoResetTimer = nil
        print("⏰ Auto-reset timer cancelled")
    }
    
    private func performAutoReset() {
        print("🔄 Performing automatic reset")
        showAllMoodButtons()
        statusBox.text = "How are you feeling today?"
        informationButton.isHidden = false
        
        // Clear the timer reference
        autoResetTimer = nil
    }
    
    // Clean up timer when view disappears
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancelAutoResetTimer()
    }
    
    deinit {
        cancelAutoResetTimer()
    }
    
    private func getStoredSiteID() -> String {
        if let siteID = UserDefaults.standard.string(forKey: "user_site_id"), !siteID.isEmpty {
            return siteID
        } else {
            return "unknown_site" // fallback if no site ID saved
        }
    }
    
    // MARK: - Automatic Student ID Management (Background)
    private func setupAutomaticStudentId() {
        // Set normal status message (no student ID visible to user)
        statusBox.text = "How are you feeling today?"
    }
    
    // FIXED: Now gets next student ID per site, maintaining each site's independent counter
    private func getNextStudentId(completion: @escaping (String) -> Void) {
        let currentSiteID = getStoredSiteID()
        
        // Query Firebase to count existing entries FOR THIS SITE ONLY
        // This preserves each site's counter: new sites start at 1, existing sites continue their count
        db.collection("mood_entries")
            .whereField("siteID", isEqualTo: currentSiteID)  // FILTER BY CURRENT SITE
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("❌ Error getting document count for site \(currentSiteID): \(error.localizedDescription)")
                    // Fallback to random number if count fails
                    let fallbackId = String(Int.random(in: 1...9999))
                    completion(fallbackId)
                    return
                }
                
                // Get count of existing documents FOR THIS SITE and add 1 for next ID
                // NEW SITE: 0 entries → next ID = 1
                // EXISTING SITE: 5 entries → next ID = 6 (continues count)
                let existingCount = querySnapshot?.documents.count ?? 0
                let nextId = String(existingCount + 1)
                print("📚 Site '\(currentSiteID)': Generated Student ID \(nextId) (existing entries: \(existingCount))")
                completion(nextId)
            }
    }
    
    // MARK: - Firebase Connection Test
    private func testFirebaseConnection() {
        print("🔥 Testing Firebase connection...")
        
        // Try to read from Firestore to test connection
        db.collection("test").document("connection").getDocument { (document, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Firebase connection error: \(error.localizedDescription)")
                } else {
                    print("✅ Firebase connection successful!")
                }
            }
        }
    }
    
    // MARK: - Firebase Functions
    private func uploadMoodToFirebase(mood: String) {
        print("🔥 Starting Firebase upload for mood: \(mood)")
        
        // Show loading state
        statusBox.text = "Saving your mood..."
        
        // Get next sequential student ID FOR CURRENT SITE (maintains independent site counters)
        getNextStudentId { [weak self] studentId in
            guard let self = self else { return }
            
            // Create mood entry with site-specific sequential student ID
            let siteID = getStoredSiteID()
            let moodEntry = MoodEntry(mood: mood, studentId: studentId, siteID: siteID)
            
            // Convert to dictionary for Firebase
            let moodData: [String: Any] = [
                "mood": moodEntry.mood,
                "timestamp": Timestamp(date: moodEntry.timestamp),
                "studentId": studentId,
                "siteID": siteID
            ]
            
            print("📝 Mood data to upload: \(moodData)")
            
            // Add timeout handling
            let timeoutTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    print("⏰ Firebase upload timeout")
                    self?.statusBox.text = "Upload timeout. Please try again."
                    // Auto-reset on timeout after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self?.performAutoReset()
                    }
                }
            }
            
            // Upload to Firebase
            self.db.collection("mood_entries").addDocument(data: moodData) { [weak self] error in
                // Cancel timeout timer
                timeoutTimer.invalidate()
                
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ Firebase upload error: \(error.localizedDescription)")
                        print("❌ Error details: \(error)")
                        
                        self?.statusBox.text = "Error: \(error.localizedDescription)"
                        // Auto-reset on error after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            self?.performAutoReset()
                        }
                    } else {
                        print("✅ Mood '\(mood)' successfully uploaded to Firebase with Student ID: \(studentId) for site: \(siteID)!")
                        self?.statusBox.text = "Thanks for letting us know!"
                        
                        // 🎯 START AUTO-RESET TIMER HERE
                        // This gives users time to see both messages:
                        // 1. "Saving your mood..." (during upload)
                        // 2. "Thanks for letting us know!" (after success)
                        // Then automatically returns to emoji selection after 3 seconds
                        self?.startAutoResetTimer()
                    }
                }
            }
        }
    }
    
    // MARK: - Mood Selection Logic
    private func handleMoodSelection(_ mood: String) {
        print("🎭 Handling mood selection: \(mood)")
        
        // Cancel any existing auto-reset timer when new selection is made
        cancelAutoResetTimer()
        
        // Hide all mood buttons
        hideAllMoodButtons()
        
        // Update local counter
        updateLocalCounter(for: mood)
        
        // Upload to Firebase
        uploadMoodToFirebase(mood: mood)
        
        // Hide information button
        informationButton.isHidden = true
    }
    
    private func hideAllMoodButtons() {
        happyButton.isHidden = true
        sarcasticButton.isHidden = true
        loveButton.isHidden = true
        angryButton.isHidden = true
        partyButton.isHidden = true
        sleepyButton.isHidden = true
        upsetButton.isHidden = true
        scaredButton.isHidden = true
        cryButton.isHidden = true
    }
    
    private func showAllMoodButtons() {
        happyButton.isHidden = false
        sarcasticButton.isHidden = false
        loveButton.isHidden = false
        angryButton.isHidden = false
        partyButton.isHidden = false
        sleepyButton.isHidden = false
        upsetButton.isHidden = false
        scaredButton.isHidden = false
        cryButton.isHidden = false
    }
    
    private func updateLocalCounter(for mood: String, shouldPrint: Bool = true) {
        switch mood {
        case "happy":
            happyCount += 1
            if shouldPrint { print("😊 Happy count = \(happyCount)") }
        case "sarcastic":
            sarcasticCount += 1
            if shouldPrint { print("😏 Sarcastic count = \(sarcasticCount)") }
        case "love":
            loveCount += 1
            if shouldPrint { print("😍 Love count = \(loveCount)") }
        case "angry":
            angryCount += 1
            if shouldPrint { print("😠 Angry count = \(angryCount)") }
        case "party":
            partyCount += 1
            if shouldPrint { print("🥳 Party count = \(partyCount)") }
        case "sleepy":
            sleepyCount += 1
            if shouldPrint { print("😴 Sleepy count = \(sleepyCount)") }
        case "upset":
            upsetCount += 1
            if shouldPrint { print("😢 Upset count = \(upsetCount)") }
        case "scared":
            scaredCount += 1
            if shouldPrint { print("😨 Scared count = \(scaredCount)") }
        case "cry":
            cryCount += 1
            if shouldPrint { print("😭 Cry count = \(cryCount)") }
        default:
            if shouldPrint { print("❓ Unknown mood: \(mood)") }
        }
    }
    
    // MARK: - IBActions
    @IBAction func happyButtonPressed(_ sender: Any) {
        handleMoodSelection("happy")
    }
    
    @IBAction func sarcasticButtonPressed(_ sender: Any) {
        handleMoodSelection("sarcastic")
    }
    
    @IBAction func loveButtonPressed(_ sender: Any) {
        handleMoodSelection("love")
    }
    
    @IBAction func angryButtonPressed(_ sender: Any) {
        handleMoodSelection("angry")
    }
    
    @IBAction func partyButtonPressed(_ sender: Any) {
        handleMoodSelection("party")
    }
    
    @IBAction func sleepyButtonPressed(_ sender: Any) {
        handleMoodSelection("sleepy")
    }
    
    @IBAction func upsetButtonPressed(_ sender: Any) {
        handleMoodSelection("upset")
    }
    
    @IBAction func scaredButtonPressed(_ sender: Any) {
        handleMoodSelection("scared")
    }
    
    @IBAction func cryButtonPressed(_ sender: Any) {
        handleMoodSelection("cry")
    }
}
