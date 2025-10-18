//
//  ResetPasswordViewController.swift
//  MoodTracker - Complete with All Fixes
//

import UIKit
import FirebaseFirestore

class ResetPasswordViewController: UIViewController {
    
    // Firebase Firestore reference
    private let db = Firestore.firestore()
    
    // Data passed from ForgotPasswordViewController
    var siteData: [String: Any] = [:]
    
    // MARK: - IBOutlets
    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var updatePasswordButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("✅ ResetPasswordViewController loaded")
        print("📋 Received site data: \(siteData)")
        
        // Debug: Check if we have the site data we need
        if let siteID = siteData["siteID"] as? String {
            print("✅ Site ID found: '\(siteID)'")
        } else {
            print("❌ WARNING: No Site ID found in passed data!")
            print("❌ Available keys in siteData: \(siteData.keys)")
        }
        
        setupTextFieldMonitoring()
        updateUpdateButtonState()
        
        // EMERGENCY FIX: If button isn't connected properly, connect it programmatically
        updatePasswordButton.addTarget(self, action: #selector(updatePasswordButtonPressed(_:)), for: .touchUpInside)
        print("🔧 Added emergency button target programmatically")
    }
    
    // MARK: - Text Field Monitoring
    private func setupTextFieldMonitoring() {
        newPasswordTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        confirmPasswordTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    @objc private func textFieldDidChange() {
        updateUpdateButtonState()
    }
    
    private func updateUpdateButtonState() {
        let newPasswordValid = !(newPasswordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let confirmPasswordValid = !(confirmPasswordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        
        let isValid = newPasswordValid && confirmPasswordValid
        updatePasswordButton.isEnabled = isValid
        updatePasswordButton.alpha = isValid ? 1.0 : 0.5
    }
    
    // MARK: - Button Actions (Handle incorrect storyboard connections)
    
    // This gets called due to incorrect storyboard connection to SignUpViewController
    @IBAction func registerButtonPressed(_ sender: Any) {
        print("🔘 === REGISTER BUTTON PRESSED METHOD CALLED ===")
        print("🔄 This method was called instead of updatePasswordButtonPressed")
        print("🔄 Redirecting to updatePassword method...")
        updatePasswordButtonPressed(sender)
    }
    
    // This gets called due to incorrect storyboard connection to SignInViewController
    @IBAction func signInButtonPressed(_ sender: Any) {
        print("🔘 === SIGN IN BUTTON PRESSED METHOD CALLED ===")
        print("🔄 This method was called instead of updatePasswordButtonPressed")
        print("🔄 Redirecting to updatePassword method...")
        updatePasswordButtonPressed(sender)
    }
    
    @IBAction func updatePasswordButtonPressed(_ sender: Any) {
        print("\n🔘 === UPDATE PASSWORD BUTTON PRESSED ===")
        print("✅ CORRECT METHOD CALLED!")
        
        // Get field values
        let newPassword = newPasswordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let confirmPassword = confirmPasswordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        print("📝 New Password Length: \(newPassword.count)")
        print("📝 Confirm Password Length: \(confirmPassword.count)")
        
        // Basic validation
        guard !newPassword.isEmpty && !confirmPassword.isEmpty else {
            print("❌ VALIDATION FAILED: Empty fields")
            return
        }
        
        guard newPassword == confirmPassword else {
            print("❌ VALIDATION FAILED: Passwords don't match")
            setPasswordMismatchErrorState()
            return
        }
        
        guard newPassword.count >= 6 else {
            print("❌ VALIDATION FAILED: Password too short")
            setPasswordTooShortErrorState()
            return
        }
        
        print("✅ Password validation passed")
        
        // Update UI to updating state
        setUpdatingState()
        
        // Update password in Firebase
        updatePasswordInFirebase(newPassword: newPassword)
    }
    
    // MARK: - Enhanced Firebase Password Update with Debugging
    private func updatePasswordInFirebase(newPassword: String) {
        print("\n🔥 === STARTING FIREBASE PASSWORD UPDATE ===")
        
        guard let targetSiteID = siteData["siteID"] as? String else {
            print("❌ CRITICAL ERROR: No site ID found in passed data")
            print("❌ siteData contents: \(siteData)")
            setUpdateFailedErrorState(message: "Site information not found")
            return
        }
        
        print("📝 Target Site ID: '\(targetSiteID)'")
        print("🔍 Searching for site document in Firebase...")
        
        // Add timeout for Firebase operation
        let timeoutTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) { _ in
            DispatchQueue.main.async {
                print("⏰ Firebase update timeout!")
                self.setUpdateFailedErrorState(message: "Update timeout - check internet connection")
            }
        }
        
        // Find the document for this site
        db.collection("registered_sites")
            .whereField("siteID", isEqualTo: targetSiteID)
            .getDocuments { [weak self] (querySnapshot, error) in
                // Cancel timeout timer
                timeoutTimer.invalidate()
                
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    print("🔄 Firebase query completed")
                    
                    if let error = error {
                        print("❌ FIREBASE QUERY ERROR: \(error.localizedDescription)")
                        print("❌ Error details: \(error)")
                        self.setUpdateFailedErrorState(message: "Database error: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        print("❌ No query response from Firebase")
                        self.setUpdateFailedErrorState(message: "No response from database")
                        return
                    }
                    
                    print("📊 Query returned \(documents.count) documents")
                    
                    guard !documents.isEmpty else {
                        print("❌ SITE DOCUMENT NOT FOUND")
                        print("❌ No documents found for Site ID: '\(targetSiteID)'")
                        self.setUpdateFailedErrorState(message: "Site document not found in database")
                        return
                    }
                    
                    print("✅ Found site document!")
                    let document = documents[0]
                    print("📄 Document ID: \(document.documentID)")
                    print("📋 Current document data: \(document.data())")
                    
                    // Update the password in the document
                    self.updateDocumentPassword(documentRef: document.reference, newPassword: newPassword, siteID: targetSiteID)
                }
            }
    }
    
    private func updateDocumentPassword(documentRef: DocumentReference, newPassword: String, siteID: String) {
        print("\n💾 === UPDATING DOCUMENT PASSWORD ===")
        print("📄 Document Reference: \(documentRef.path)")
        print("🔒 New Password Length: \(newPassword.count)")
        
        let updateData: [String: Any] = [
            "password": newPassword,
            "passwordLastUpdated": Timestamp(date: Date())
        ]
        
        print("📝 Update data: \(updateData)")
        
        // Add another timeout for the update operation
        let updateTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { _ in
            DispatchQueue.main.async {
                print("⏰ Password update timeout!")
                self.setUpdateFailedErrorState(message: "Update operation timeout")
            }
        }
        
        documentRef.updateData(updateData) { [weak self] error in
            // Cancel timeout timer
            updateTimer.invalidate()
            
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                print("🔄 Password update operation completed")
                
                if let error = error {
                    print("❌ PASSWORD UPDATE FAILED: \(error.localizedDescription)")
                    print("❌ Error details: \(error)")
                    self.setUpdateFailedErrorState(message: "Update failed: \(error.localizedDescription)")
                } else {
                    print("✅ === PASSWORD UPDATE SUCCESSFUL! ===")
                    print("✅ Password updated for Site ID: '\(siteID)'")
                    self.setUpdateSuccessState()
                    
                    // Verify the update by reading the document back
                    self.verifyPasswordUpdate(documentRef: documentRef)
                }
            }
        }
    }
    
    // MARK: - Verification (Optional but helpful for debugging)
    private func verifyPasswordUpdate(documentRef: DocumentReference) {
        print("\n🔍 Verifying password update...")
        
        documentRef.getDocument { (document, error) in
            if let error = error {
                print("❌ Verification read failed: \(error.localizedDescription)")
            } else if let document = document, document.exists {
                let data = document.data() ?? [:]
                if let updatedPassword = data["password"] as? String {
                    print("✅ Verification: Password field exists and has \(updatedPassword.count) characters")
                } else {
                    print("❌ Verification: Password field not found in document")
                }
                if let lastUpdated = data["passwordLastUpdated"] as? Timestamp {
                    print("✅ Verification: passwordLastUpdated = \(lastUpdated.dateValue())")
                } else {
                    print("⚠️ Verification: passwordLastUpdated field not found")
                }
            } else {
                print("❌ Verification: Document doesn't exist")
            }
        }
    }
    
    // MARK: - UI State Management
    private func setUpdatingState() {
        print("🔄 Setting UPDATING state")
        updatePasswordButton.isEnabled = false
        updatePasswordButton.setTitle("💾 UPDATING PASSWORD...", for: .normal)
        updatePasswordButton.backgroundColor = .systemBlue
        updatePasswordButton.layer.borderWidth = 3
        updatePasswordButton.layer.borderColor = UIColor.blue.cgColor
        updatePasswordButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
    }
    
    private func setUpdateSuccessState() {
        print("✅ Setting UPDATE SUCCESS state")
        
        updatePasswordButton.setTitle("✅ PASSWORD UPDATED!", for: .normal)
        updatePasswordButton.backgroundColor = .systemGreen
        updatePasswordButton.layer.borderWidth = 3
        updatePasswordButton.layer.borderColor = UIColor.green.cgColor
        updatePasswordButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        
        // Navigate back to sign-in screen after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.goBackToSignInScreen()
        }
    }
    
    private func setUpdateFailedErrorState(message: String) {
        print("❌ Setting UPDATE FAILED state: \(message)")
        
        updatePasswordButton.setTitle("❌ UPDATE FAILED", for: .normal)
        updatePasswordButton.backgroundColor = .systemRed
        updatePasswordButton.layer.borderWidth = 3
        updatePasswordButton.layer.borderColor = UIColor.red.cgColor
        updatePasswordButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        
        // Reset after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.resetToNormalState()
        }
    }
    
    private func setPasswordMismatchErrorState() {
        updatePasswordButton.setTitle("❌ PASSWORDS DON'T MATCH", for: .normal)
        updatePasswordButton.backgroundColor = .systemRed
        updatePasswordButton.layer.borderWidth = 3
        updatePasswordButton.layer.borderColor = UIColor.red.cgColor
        updatePasswordButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.resetToNormalState()
        }
    }
    
    private func setPasswordTooShortErrorState() {
        updatePasswordButton.setTitle("❌ PASSWORD TOO SHORT (MIN 6)", for: .normal)
        updatePasswordButton.backgroundColor = .systemRed
        updatePasswordButton.layer.borderWidth = 3
        updatePasswordButton.layer.borderColor = UIColor.red.cgColor
        updatePasswordButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.resetToNormalState()
        }
    }
    
    private func resetToNormalState() {
        updatePasswordButton.setTitle("Set Password", for: .normal)
        updatePasswordButton.backgroundColor = .systemGray
        updatePasswordButton.layer.borderWidth = 0
        updatePasswordButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        updateUpdateButtonState()
    }
    
    // MARK: - Navigation
    private func goBackToSignInScreen() {
        print("🚀 Going back to welcome screen")
        print("🔍 Current navigation stack:")
        
        if let navigationController = navigationController {
            // Debug: Print the current navigation stack
            for (index, vc) in navigationController.viewControllers.enumerated() {
                print("  \(index): \(String(describing: type(of: vc)))")
            }
            
            // Check if Welcome screen is in the stack
            var foundWelcome = false
            for viewController in navigationController.viewControllers {
                let vcClassName = String(describing: type(of: viewController))
                if vcClassName == "UIViewController" && (viewController.title == "Welcome" ||
                   String(describing: viewController).contains("Welcome")) {
                    print("✅ Found Welcome screen in stack!")
                    navigationController.popToViewController(viewController, animated: true)
                    foundWelcome = true
                    return
                }
            }
            
            if !foundWelcome {
                print("❌ Welcome screen NOT in navigation stack!")
                print("🚀 Creating fresh welcome screen using nuclear option")
            }
        }
        
        // Nuclear option: Create a completely fresh welcome screen
        print("🚀 Using nuclear option - creating fresh welcome screen")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // Use the initial view controller from storyboard (which should be Welcome)
        if let welcomeVC = storyboard.instantiateInitialViewController() {
            print("✅ Got initial view controller from storyboard")
            
            // Option 1: Replace the entire window's root view controller
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController = welcomeVC
                window.makeKeyAndVisible()
                print("✅ Set fresh welcome screen as window root")
                return
            }
            
            // Option 2: Try the old way for compatibility
            if let window = view.window {
                window.rootViewController = welcomeVC
                window.makeKeyAndVisible()
                print("✅ Set fresh welcome screen as window root (compatibility)")
                return
            }
            
            // Option 3: Replace the navigation controller's entire stack
            if let navController = navigationController {
                navController.setViewControllers([welcomeVC], animated: true)
                print("✅ Set fresh welcome screen as only view controller in stack")
                return
            }
        }
        
        // Final fallback
        print("❌ All methods failed, dismissing to root")
        dismiss(animated: true, completion: nil)
    }
}
