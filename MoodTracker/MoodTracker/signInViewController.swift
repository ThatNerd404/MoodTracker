//
//  SignInViewController.swift
//  MoodTracker
//
//  Created by Code Academy on 1/25/25.
//

import UIKit
import FirebaseFirestore

class SignInViewController: UIViewController {
    
    // Firebase Firestore reference
    private let db = Firestore.firestore()
    
    // MARK: - IBOutlets
    @IBOutlet weak var siteIDTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("🏫 Sign In page loaded - Site ID field is empty")
        
        // Set up text field delegates to monitor input
        siteIDTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        
        // Initially disable the sign-in button
        updateSignInButtonState()
    }
    
    // MARK: - Text Field Monitoring
    @objc private func textFieldDidChange() {
        updateSignInButtonState()
    }
    
    private func updateSignInButtonState() {
        let siteIDValid = !(siteIDTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let passwordValid = !(passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        
        let isValid = siteIDValid && passwordValid
        signInButton.isEnabled = isValid
        signInButton.alpha = isValid ? 1.0 : 0.5
    }
    
    // MARK: - Firebase Authentication with debug logs
    private func authenticateCredentials(siteID: String, password: String, completion: @escaping (Bool, String) -> Void) {
        print("🔍 Authenticating credentials for Site ID: '\(siteID)'")
        
        db.collection("registered_sites")
            .whereField("siteID", isEqualTo: siteID)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("❌ Authentication error: \(error.localizedDescription)")
                    completion(false, "Network error. Please try again.")
                    return
                }
                
                guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                    print("❌ Site ID '\(siteID)' not found")
                    completion(false, "Site ID '\(siteID)' is not registered.")
                    return
                }
                
                let document = documents[0]
                print("📄 SignIn authenticating document ID: \(document.documentID)")
                let registeredData = document.data()
                let storedPassword = registeredData["password"] as? String ?? "(nil)"
                print("Stored password: '\(storedPassword)' (length: \(storedPassword.count))")
                print("Input password: '\(password)' (length: \(password.count))")
                
                if storedPassword == password {
                    print("✅ Authentication successful for Site ID: '\(siteID)'")
                    completion(true, "Sign in successful!")
                } else {
                    print("❌ Password incorrect for Site ID: '\(siteID)'")
                    completion(false, "Incorrect password for Site ID '\(siteID)'.")
                }
            }
    }
    
    // MARK: - Sign In Process
    @IBAction func signInButtonPressed(_ sender: Any) {
        print("\n🔘 SIGN IN BUTTON PRESSED")
        
        // Get validated data
        let siteID = siteIDTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        print("📝 Site ID: '\(siteID)' | Password: '\(password)'")
        
        // Basic validation
        guard !siteID.isEmpty && !password.isEmpty else {
            print("❌ VALIDATION FAILED: Empty fields")
            showAlert(title: "Missing Information", message: "Please enter both Site ID and Password.")
            return
        }
        
        // Set checking state
        setCheckingState()
        
        // Authenticate with Firebase
        authenticateCredentials(siteID: siteID, password: password) { [weak self] success, message in
            DispatchQueue.main.async {
                if success {
                    print("✅ AUTHENTICATION SUCCESSFUL")
                    self?.authenticationSuccessful(siteID: siteID)
                } else {
                    print("❌ AUTHENTICATION FAILED: \(message)")
                    self?.authenticationFailed(message: message)
                }
            }
        }
    }
    
    // MARK: - UI State Management
    private func setCheckingState() {
        print("🔄 Setting CHECKING state")
        signInButton.isEnabled = false
        signInButton.setTitle("🔍 CHECKING CREDENTIALS...", for: .normal)
        signInButton.backgroundColor = .systemOrange
        signInButton.layer.borderWidth = 3
        signInButton.layer.borderColor = UIColor.orange.cgColor
        signInButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
    }
    
    private func authenticationSuccessful(siteID: String) {
        print("✅ Setting SUCCESS state")
        
        // Save the site ID for use in the app
        UserDefaults.standard.set(siteID, forKey: "user_site_id")
        print("🏫 Site ID saved: \(siteID)")
        
        // Update button to success state
        signInButton.setTitle("✅ SIGN IN SUCCESSFUL!", for: .normal)
        signInButton.backgroundColor = .systemGreen
        signInButton.layer.borderWidth = 3
        signInButton.layer.borderColor = UIColor.green.cgColor
        signInButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        
        // Navigate to main app after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.navigateToMainApp()
        }
    }
    
    private func authenticationFailed(message: String) {
        print("❌ Setting AUTHENTICATION FAILED state")
        
        // Update button to error state
        signInButton.setTitle("❌ SIGN IN FAILED", for: .normal)
        signInButton.backgroundColor = .systemRed
        signInButton.layer.borderWidth = 3
        signInButton.layer.borderColor = UIColor.red.cgColor
        signInButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        
        // Show error alert
        showAlert(title: "Sign In Failed", message: message)
        
        // Reset to normal state after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.resetToNormalState()
        }
    }
    
    private func resetToNormalState() {
        print("🔄 Resetting to NORMAL state")
        signInButton.setTitle("Sign In to Tracker", for: .normal)
        signInButton.backgroundColor = .systemGray2 // Match your original button color
        signInButton.layer.borderWidth = 0
        signInButton.titleLabel?.font = UIFont.systemFont(ofSize: 30) // Match your original font size
        updateSignInButtonState() // Re-enable based on field validation
    }
    
    // MARK: - Navigation - SIMPLIFIED VERSION
    private func navigateToMainApp() {
        print("🚀 Navigating to main app using existing segue")
        
        // Since there's already a segue from the sign-in button to the main app,
        // we can use it by temporarily removing the action and letting the segue handle it
        
        // Check if there's a segue connected to the button
        if let segues = view.subviews.compactMap({ $0 as? UIButton }).first(where: { $0 == signInButton }) {
            print("✅ Found sign-in button, checking for segues...")
        }
        
        // Alternative approach: Manually instantiate and navigate
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // Try to get the main view controller using storyboard identifier first
        if let mainVC = storyboard.instantiateViewController(withIdentifier: "BYZ-38-t0r") as? ViewController {
            print("✅ Main view controller instantiated successfully")
            
            // Debug navigation controller status
            if let navController = navigationController {
                print("✅ Navigation controller available")
                print("📚 Current stack: \(navController.viewControllers.count) view controllers")
                
                // Push to navigation stack
                navController.pushViewController(mainVC, animated: true)
                print("✅ Successfully pushed to navigation stack")
                
            } else {
                print("❌ No navigation controller - using modal presentation")
                mainVC.modalPresentationStyle = .fullScreen
                present(mainVC, animated: true) {
                    print("✅ Successfully presented main app modally")
                }
            }
            
        } else {
            print("❌ CRITICAL ERROR: Could not instantiate main view controller")
            print("❌ Make sure to set Storyboard ID 'BYZ-38-t0r' for the main ViewController in Interface Builder")
            
            // Fallback: Show error alert
            showAlert(title: "Navigation Error", message: "Unable to access main app. Please set Storyboard ID 'BYZ-38-t0r' in Interface Builder.")
        }
    }
    
    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        guard isViewLoaded && view.window != nil else { return }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // Optional: Clear saved site ID (for testing)
    @IBAction func clearSavedSiteID(_ sender: Any) {
        UserDefaults.standard.removeObject(forKey: "user_site_id")
        siteIDTextField.text = ""
        passwordTextField.text = ""
        updateSignInButtonState()
        print("🗑️ Saved site ID cleared")
    }
}
