//
//  ForgotPasswordViewController.swift
//  MoodTracker - Matches Current Storyboard Setup
//

import UIKit
import FirebaseFirestore

class ForgotPasswordViewController: UIViewController {
    
    // Firebase Firestore reference
    private let db = Firestore.firestore()
    
    // Store found site data
    private var foundSiteData: [String: Any] = [:]
    
    // MARK: - IBOutlets
    @IBOutlet weak var siteIDTextField: UITextField!
    @IBOutlet weak var resetPasswordButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("✅ ForgotPasswordViewController loaded")
        
        setupTextFieldMonitoring()
        updateResetButtonState()
        
        // REMOVED: Programmatic navigation controller setup that was breaking storyboard segues
        // Since we're using storyboard segues with back buttons, we don't need this
    }
    
    // MARK: - Text Field Monitoring
    private func setupTextFieldMonitoring() {
        siteIDTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    @objc private func textFieldDidChange() {
        updateResetButtonState()
    }
    
    private func updateResetButtonState() {
        let siteIDValid = !(siteIDTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        
        let isValid = siteIDValid
        resetPasswordButton.isEnabled = isValid
        resetPasswordButton.alpha = isValid ? 1.0 : 0.5
    }
    
    // MARK: - Firebase Site Check
    private func checkForSite(siteID: String, completion: @escaping (Bool, [String: Any]?) -> Void) {
        print("🔍 CHECKING FOR SITE: '\(siteID)'")
        
        db.collection("registered_sites")
            .whereField("siteID", isEqualTo: siteID)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("❌ QUERY ERROR: \(error.localizedDescription)")
                    completion(false, nil)
                    return
                }
                
                let documentCount = querySnapshot?.documents.count ?? 0
                let siteExists = documentCount > 0
                
                print("📊 QUERY RESULT: Found \(documentCount) documents")
                print(siteExists ? "✅ SITE FOUND" : "❌ SITE NOT FOUND")
                
                if siteExists {
                    if let siteData = querySnapshot?.documents.first?.data(), !siteData.isEmpty {
                        completion(true, siteData)
                    } else {
                        completion(false, nil) // Malformed or empty document
                    }
                } else {
                    completion(false, nil)
                }
            }
    }
    
    // MARK: - Reset Password Process
    @IBAction func resetPasswordButtonPressed(_ sender: Any) {
        print("\n🔘 RESET PASSWORD BUTTON PRESSED")
        
        let siteID = siteIDTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        print("📝 Site ID: '\(siteID)'")
        
        guard !siteID.isEmpty else {
            print("❌ VALIDATION FAILED: Empty field")
            return
        }
        
        setCheckingState()
        
        checkForSite(siteID: siteID) { [weak self] exists, siteData in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if exists, let siteData = siteData, !siteData.isEmpty {
                    print("✅ SITE FOUND - PROCEEDING TO RESET")
                    self.proceedToPasswordReset(siteID: siteID, siteData: siteData)
                } else {
                    print("❌ SITE NOT FOUND - SHOWING ERROR STATE")
                    self.setSiteNotFoundErrorState(siteID: siteID)
                }
            }
        }
    }
    
    // MARK: - UI State Management
    private func setCheckingState() {
        print("🔄 Setting CHECKING state")
        DispatchQueue.main.async {
            self.resetPasswordButton.isEnabled = false
            self.resetPasswordButton.setTitle("🔍 CHECKING SITE...", for: .normal)
            self.resetPasswordButton.backgroundColor = .systemOrange
            self.resetPasswordButton.layer.borderWidth = 3
            self.resetPasswordButton.layer.borderColor = UIColor.orange.cgColor
            self.resetPasswordButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
            
            print("✅ Button should now be ORANGE")
        }
    }
    
    private func setSiteNotFoundErrorState(siteID: String) {
        print("❌ Setting SITE NOT FOUND ERROR state")
        
        DispatchQueue.main.async {
            self.resetPasswordButton.isEnabled = false
            self.resetPasswordButton.setTitle("❌ SITE ID '\(siteID)' NOT FOUND", for: .normal)
            self.resetPasswordButton.backgroundColor = .systemRed
            self.resetPasswordButton.layer.borderWidth = 5
            self.resetPasswordButton.layer.borderColor = UIColor.red.cgColor
            self.resetPasswordButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
            self.resetPasswordButton.titleLabel?.textColor = .white
            
            print("✅ Button should now be RED and say 'SITE ID NOT FOUND'")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            self.resetToNormalState()
        }
    }
    
    private func setSiteFoundState() {
        print("✅ Setting SITE FOUND state")
        DispatchQueue.main.async {
            self.resetPasswordButton.isEnabled = false
            self.resetPasswordButton.setTitle("✅ SITE VERIFIED!", for: .normal)
            self.resetPasswordButton.backgroundColor = .systemGreen
            self.resetPasswordButton.layer.borderWidth = 3
            self.resetPasswordButton.layer.borderColor = UIColor.green.cgColor
            self.resetPasswordButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        }
    }
    
    private func resetToNormalState() {
        print("🔄 Resetting to NORMAL state")
        resetPasswordButton.setTitle("Reset Password", for: .normal)
        resetPasswordButton.backgroundColor = .systemGray
        resetPasswordButton.layer.borderWidth = 0
        resetPasswordButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        updateResetButtonState()
    }
    
    // MARK: - Navigation Logic
    private func proceedToPasswordReset(siteID: String, siteData: [String: Any]) {
        setSiteFoundState()
        
        foundSiteData = siteData
        foundSiteData["siteID"] = siteID
        
        print("📝 Stored site data: \(foundSiteData)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.navigateToResetPasswordScreen()
        }
    }
    
    private func navigateToResetPasswordScreen() {
        print("🚀 Navigating to reset password screen")
        
        // Debug: Check navigation controller status
        if let navController = navigationController {
            print("✅ Navigation controller found: \(navController)")
            print("📚 Current view controllers in stack: \(navController.viewControllers.count)")
        } else {
            print("❌ No navigation controller found!")
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let resetVC = storyboard.instantiateViewController(withIdentifier: "ResetPasswordViewController") as? ResetPasswordViewController {
            resetVC.siteData = foundSiteData
            print("✅ Site data passed to Reset Password screen")
            print("📝 Site data contents: \(foundSiteData)")
            
            // Try navigation controller first
            if let navController = navigationController {
                navController.pushViewController(resetVC, animated: true)
                print("✅ Successfully navigated using navigation controller")
            } else {
                // Fallback: Present modally if navigation controller is not available
                print("⚠️ No navigation controller - presenting modally as fallback")
                resetVC.modalPresentationStyle = .fullScreen
                present(resetVC, animated: true) {
                    print("✅ Successfully presented reset password screen modally")
                }
            }
        } else {
            print("❌ Could not instantiate ResetPasswordViewController")
            print("❌ Make sure you set Storyboard ID to 'ResetPasswordViewController' in Interface Builder")
        }
    }
}
