/*
  SiteIdentifierViewController.swift
  MoodTracker

  Proof of Concept created by Dakota Myers, Code Academy on 1/25/25.
  Details: Created original Xcode project; completed story board UI, basic functions to handle emoji counts
 
  Code Academy Spring 2025 Intern Developers:
  Details: Added additional functionality to proof of concept, trialed different back-end solutions, trialed multiple UI setups
 
    Aavash Kuikel
    Ahmed Elrayah
 
  Code Academy Summer 2025 Intern Developers:
  Detalis: Moved project into alpha version stage; set up login screen, password security, changed UI for a youth-centric feel, 
 
    Ahmed Elrayah
    Chirag Dhungana
    Eric Fitih
    Joshua Bays
    Nancy Ruiz
    Vishnu Yadali
    
*/

import UIKit
import FirebaseFirestore

class SiteIdentifierViewController: UIViewController {
    
    // Firebase Firestore reference
    private let db = Firestore.firestore()
    
    // MARK: - IBOutlets
    @IBOutlet weak var siteTableView: UITableView!  // Connect this to your table view in storyboard
    
    // MARK: - Table Data
    private var tableData: [SiteTableRow] = []
    private var currentLoadedSiteID: String = "" // Track which site data is currently loaded
    
    // MARK: - Data Structure
    struct SiteTableRow {
        let title: String
        let value: String
        let isHeader: Bool
        
        init(title: String, value: String, isHeader: Bool = false) {
            self.title = title
            self.value = value
            self.isHeader = isHeader
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("🔍 Site Identifier Controller - Testing outlet connection...")
        print("siteTableView: \(siteTableView != nil ? "✅ Connected" : "❌ Not connected")")
        
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("🔄 SiteIdentifierViewController appearing - checking for site changes")
        
        let currentSiteID = getStoredSiteID()
        print("📋 Current site ID: '\(currentSiteID)' | Previously loaded: '\(currentLoadedSiteID)'")
        
        // Force refresh data if site changed or if no data loaded yet
        if currentSiteID != currentLoadedSiteID || tableData.isEmpty {
            print("🔄 Site changed or no data - forcing fresh reload")
            clearCachedData()
            loadSiteData()
        } else {
            print("✅ Same site - data already current")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Double-check data is current after view fully appears
        refreshDataIfNeeded()
    }
    
    private func getStoredSiteID() -> String {
        if let siteID = UserDefaults.standard.string(forKey: "user_site_id"), !siteID.isEmpty {
            return siteID
        } else {
            return "unknown_site"
        }
    }
    
    private func setupTableView() {
        guard let siteTableView = siteTableView else {
            print("❌ siteTableView outlet not connected!")
            return
        }
        
        siteTableView.dataSource = self
        siteTableView.delegate = self
        siteTableView.backgroundColor = UIColor.systemBackground
        siteTableView.separatorStyle = .singleLine
        siteTableView.layer.cornerRadius = 8
        siteTableView.layer.borderWidth = 1
        siteTableView.layer.borderColor = UIColor.systemGray4.cgColor
        
        // Show loading data initially
        showLoadingData()
    }
    
    private func clearCachedData() {
        print("🗑️ Clearing cached site data")
        tableData = []
        currentLoadedSiteID = ""
        showLoadingData()
    }
    
    private func showLoadingData() {
        let currentSiteID = getStoredSiteID()
        tableData = [
            SiteTableRow(title: "📊 Site Information", value: "", isHeader: true),
            SiteTableRow(title: "Current Site", value: currentSiteID),
            SiteTableRow(title: "Status", value: "Loading fresh data from Firebase...")
        ]
        siteTableView?.reloadData()
    }
    
    private func refreshDataIfNeeded() {
        let currentSiteID = getStoredSiteID()
        if currentSiteID != currentLoadedSiteID {
            print("⚠️ Site mismatch detected in viewDidAppear - forcing refresh")
            clearCachedData()
            loadSiteData()
        }
    }
    
    // MARK: - Firebase Data Loading
    private func loadSiteData() {
        let currentSiteID = getStoredSiteID()
        print("🔥 Site Controller - Loading FRESH data from Firebase for site: '\(currentSiteID)'")
        
        // Update the currently loaded site ID immediately
        currentLoadedSiteID = currentSiteID

        // Query mood entries from Firebase FOR CURRENT SITE ONLY
        db.collection("mood_entries")
            .whereField("siteID", isEqualTo: currentSiteID)
            .getDocuments { [weak self] (querySnapshot, error) in
                DispatchQueue.main.async {
                    // Double-check we're still on the same site (user didn't switch during load)
                    let latestSiteID = self?.getStoredSiteID() ?? ""
                    if latestSiteID != currentSiteID {
                        print("⚠️ Site changed during data load - canceling this load")
                        return
                    }
                    
                    if let error = error {
                        print("❌ Site Controller - Error getting mood entries: \(error.localizedDescription)")
                        self?.displayError(error: error, siteID: currentSiteID)
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        print("📝 Site Controller - No documents found in Firebase for site: \(currentSiteID)")
                        self?.displayNoData(siteID: currentSiteID)
                        return
                    }
                    
                    print("✅ Site Controller - Found \(documents.count) mood entries in Firebase for site: \(currentSiteID)")
                    
                    // Convert Firebase documents to mood data
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
                        self?.displayNoData(siteID: currentSiteID)
                    } else {
                        self?.displaySiteData(entries: moodEntries, siteID: currentSiteID)
                    }
                }
            }
    }
    
    // MARK: - Display Site Information
    private func displaySiteData(entries: [(mood: String, timestamp: Date, studentId: String)], siteID: String) {
        print("📊 Displaying data for site: '\(siteID)' with \(entries.count) entries")

        // Calculate mood counts for most/least used
        var moodCounts: [String: Int] = [:]
        for entry in entries {
            moodCounts[entry.mood, default: 0] += 1
        }
        
        let sortedMoods = moodCounts.sorted { $0.value > $1.value }
        let mostUsed = sortedMoods.first
        let leastUsed = sortedMoods.filter({ $0.value > 0 }).min(by: { $0.value < $1.value })
        
        // Build table data
        tableData = [
            SiteTableRow(title: "🏫 Site Information", value: "", isHeader: true),
            SiteTableRow(title: "Site ID", value: siteID),
            SiteTableRow(title: "Data Last Updated", value: formatCurrentTime()),
            SiteTableRow(title: "Most Used Emoji", value: formatMoodData(mostUsed)),
            SiteTableRow(title: "Least Used Emoji", value: formatMoodData(leastUsed)),
            SiteTableRow(title: "📊 Statistics", value: "", isHeader: true),
            SiteTableRow(title: "Total Submissions", value: "\(entries.count)"),
            SiteTableRow(title: "Active Students", value: "\(Set(entries.map { $0.studentId }).count)"),
            SiteTableRow(title: "Different Moods Used", value: "\(moodCounts.count)"),
            SiteTableRow(title: "🔥 Status", value: "", isHeader: true),
            SiteTableRow(title: "Firebase Connection", value: "Connected to Firebase Cloud"),
            SiteTableRow(title: "Current User Session", value: siteID)
        ]

        siteTableView?.reloadData()
        print("✅ Site data displayed for: '\(siteID)'")
    }
    
    private func formatCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
    
    private func formatMoodData(_ moodData: (key: String, value: Int)?) -> String {
        guard let moodData = moodData else {
            return "No data yet"
        }
        let emoji = getEmojiForMood(moodData.key)
        return "\(emoji) \(moodData.key.capitalized) (\(moodData.value))"
    }
    
    private func getEmojiForMood(_ mood: String) -> String {
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
    
    private func displayError(error: Error, siteID: String) {
        tableData = [
            SiteTableRow(title: "❌ Connection Error", value: "", isHeader: true),
            SiteTableRow(title: "Site ID", value: siteID),
            SiteTableRow(title: "Error", value: error.localizedDescription),
            SiteTableRow(title: "Solution", value: "Check internet connection and Firebase setup")
        ]
        
        siteTableView?.reloadData()
    }
    
    private func displayNoData(siteID: String) {
        tableData = [
            SiteTableRow(title: "🏫 Site Information", value: "", isHeader: true),
            SiteTableRow(title: "Site ID", value: siteID),
            SiteTableRow(title: "Data Last Updated", value: formatCurrentTime()),
            SiteTableRow(title: "Most Used Emoji", value: "No data yet"),
            SiteTableRow(title: "Least Used Emoji", value: "No data yet"),
            SiteTableRow(title: "📊 Statistics", value: "", isHeader: true),
            SiteTableRow(title: "Total Submissions", value: "0"),
            SiteTableRow(title: "Active Students", value: "0"),
            SiteTableRow(title: "Different Moods Used", value: "0"),
            SiteTableRow(title: "📝 Status", value: "", isHeader: true),
            SiteTableRow(title: "Message", value: "No mood entries for this site yet"),
            SiteTableRow(title: "Firebase Connection", value: "Connected to Firebase Cloud"),
            SiteTableRow(title: "Current User Session", value: siteID)
        ]
        
        siteTableView?.reloadData()
    }
    
    // MARK: - Actions
    @IBAction func refreshSiteDataButtonPressed(_ sender: Any) {
        print("🔄 Site Controller - Manual refresh requested")
        clearCachedData()
        loadSiteData()
    }
    
    @IBAction func logOutFromSiteButtonPressed(_ sender: Any) {
        let currentSiteID = getStoredSiteID()
        let alert = UIAlertController(title: "Log Out",
                                    message: "Are you sure you want to log out from site '\(currentSiteID)'?",
                                    preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { _ in
            // Clear the cached data and site ID
            self.clearCachedData()
            UserDefaults.standard.removeObject(forKey: "user_site_id")
            
            // Navigate back to welcome screen
            self.navigationController?.popToRootViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
}

// MARK: - UITableView DataSource & Delegate
extension SiteIdentifierViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "SiteCell")
        let rowData = tableData[indexPath.row]
        
        // Configure cell style
        cell.selectionStyle = .none
        
        if rowData.isHeader {
            // Header style
            cell.textLabel?.text = rowData.title
            cell.detailTextLabel?.text = nil
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 18)
            cell.textLabel?.textColor = UIColor.systemBlue
            cell.backgroundColor = UIColor.systemGray6
            cell.textLabel?.textAlignment = .center
        } else {
            // Regular row style
            cell.textLabel?.text = rowData.title
            cell.detailTextLabel?.text = rowData.value
            cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
            cell.textLabel?.textColor = UIColor.label
            cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            cell.detailTextLabel?.textColor = UIColor.systemBlue
            cell.backgroundColor = UIColor.systemBackground
            cell.textLabel?.textAlignment = .left
            
            // Handle long text in detail
            cell.detailTextLabel?.numberOfLines = 0
            cell.detailTextLabel?.lineBreakMode = .byWordWrapping
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let rowData = tableData[indexPath.row]
        if rowData.isHeader {
            return 40
        } else {
            // Auto height for longer text
            return UITableView.automaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}
