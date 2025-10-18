//
//  SignUpViewController.swift
//  MoodTracker - CLEAN VERSION
//

import UIKit
import FirebaseFirestore

class SignUpViewController: UIViewController {
    
    // Firebase Firestore reference
    private let db = Firestore.firestore()
    
    // MARK: - IBOutlets
    @IBOutlet weak var siteIDTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("✅ SignUpViewController loaded")
        
        setupTextFieldMonitoring()
        updateRegisterButtonState()
    }
    
    // MARK: - Text Field Monitoring
    private func setupTextFieldMonitoring() {
        siteIDTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    @objc private func textFieldDidChange() {
        updateRegisterButtonState()
    }
    
    private func updateRegisterButtonState() {
        let siteIDValid = !(siteIDTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let passwordValid = !(passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        
        let isValid = siteIDValid && passwordValid
        registerButton.isEnabled = isValid
        registerButton.alpha = isValid ? 1.0 : 0.5
    }
    
    // MARK: - Firebase Duplicate Check
    private func checkForDuplicate(siteID: String, completion: @escaping (Bool) -> Void) {
        print("🔍 CHECKING FOR DUPLICATE: '\(siteID)'")
        
        db.collection("registered_sites")
            .whereField("siteID", isEqualTo: siteID)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("❌ QUERY ERROR: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                let documentCount = querySnapshot?.documents.count ?? 0
                let isDuplicate = documentCount > 0
                
                print("📊 QUERY RESULT: Found \(documentCount) documents")
                print(isDuplicate ? "🚫 DUPLICATE FOUND" : "✅ NO DUPLICATE")
                
                completion(isDuplicate)
            }
    }
    
    // MARK: - Registration Process
    @IBAction func registerButtonPressed(_ sender: Any) {
        print("\n🔘 REGISTER BUTTON PRESSED")
        
        // Get field values
        let siteID = siteIDTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        print("📝 Site ID: '\(siteID)' | Password: '\(password)'")
        
        // Basic validation
        guard !siteID.isEmpty && !password.isEmpty else {
            print("❌ VALIDATION FAILED: Empty fields")
            return
        }
        
        // Update UI to checking state
        setCheckingState()
        
        // Check for duplicates
        checkForDuplicate(siteID: siteID) { [weak self] isDuplicate in
            DispatchQueue.main.async {
                if isDuplicate {
                    print("🚫 REGISTRATION BLOCKED - SHOWING ERROR STATE")
                    self?.setDuplicateErrorState(siteID: siteID)
                } else {
                    print("✅ NO DUPLICATE - PROCEEDING WITH REGISTRATION")
                    self?.proceedWithRegistration(siteID: siteID, password: password)
                }
            }
        }
    }
    
    // MARK: - UI State Management
    private func setCheckingState() {
        print("🔄 Setting CHECKING state")
        DispatchQueue.main.async {
            self.registerButton.isEnabled = false
            self.registerButton.setTitle("🔍 CHECKING FOR DUPLICATES...", for: .normal)
            self.registerButton.backgroundColor = .systemOrange
            self.registerButton.layer.borderWidth = 3
            self.registerButton.layer.borderColor = UIColor.orange.cgColor
            self.registerButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
            
            print("✅ Button should now be ORANGE")
        }
    }
    
    private func setDuplicateErrorState(siteID: String) {
        print("🚫 Setting DUPLICATE ERROR state")
        
        DispatchQueue.main.async {
            self.registerButton.isEnabled = false
            self.registerButton.setTitle("❌ SITE ID '\(siteID)' ALREADY EXISTS", for: .normal)
            self.registerButton.backgroundColor = .systemRed
            self.registerButton.layer.borderWidth = 5
            self.registerButton.layer.borderColor = UIColor.red.cgColor
            self.registerButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
            self.registerButton.titleLabel?.textColor = .white
            
            print("✅ Button should now be RED and say 'SITE ID ALREADY EXISTS'")
        }
        
        // Reset after 6 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            self.resetToNormalState()
        }
    }
    
    private func setRegistrationInProgressState() {
        print("💾 Setting REGISTRATION IN PROGRESS state")
        DispatchQueue.main.async {
            self.registerButton.isEnabled = false
            self.registerButton.setTitle("💾 CREATING ACCOUNT...", for: .normal)
            self.registerButton.backgroundColor = .systemBlue
            self.registerButton.layer.borderWidth = 2
            self.registerButton.layer.borderColor = UIColor.blue.cgColor
            self.registerButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        }
    }
    
    private func setSuccessState(siteID: String) {
        print("✅ Setting SUCCESS state")
        registerButton.isEnabled = false
        registerButton.setTitle("✅ REGISTRATION COMPLETE!", for: .normal)
        registerButton.backgroundColor = .systemGreen
        registerButton.layer.borderWidth = 3
        registerButton.layer.borderColor = UIColor.green.cgColor
        registerButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        
        // Show success message for 2 seconds, then go back to welcome screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.goBackToWelcomeScreen()
        }
    }
    
    private func setErrorState(error: Error) {
        print("❌ Setting ERROR state")
        registerButton.isEnabled = false
        registerButton.setTitle("❌ REGISTRATION FAILED", for: .normal)
        registerButton.backgroundColor = .systemRed
        registerButton.layer.borderWidth = 3
        registerButton.layer.borderColor = UIColor.red.cgColor
        registerButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        
        // Reset after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.resetToNormalState()
        }
    }
    
    private func resetToNormalState() {
        print("🔄 Resetting to NORMAL state")
        registerButton.setTitle("Register", for: .normal)
        registerButton.backgroundColor = .systemGray
        registerButton.layer.borderWidth = 0
        registerButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        updateRegisterButtonState()
    }
    
    // MARK: - Registration Logic
    private func proceedWithRegistration(siteID: String, password: String) {
        setRegistrationInProgressState()
        
        let registrationData: [String: Any] = [
            "siteID": siteID,
            "password": password,
            "registrationDate": Timestamp(date: Date()),
            "isActive": true
        ]
        
        print("📝 Saving registration data: \(registrationData)")
        
        db.collection("registered_sites").addDocument(data: registrationData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ REGISTRATION FAILED: \(error.localizedDescription)")
                    self?.setErrorState(error: error)
                } else {
                    print("✅ REGISTRATION SUCCESSFUL!")
                    UserDefaults.standard.set(siteID, forKey: "user_site_id")
                    self?.setSuccessState(siteID: siteID)
                }
            }
        }
    }
    
    // MARK: - Simple Navigation Back
    private func goBackToWelcomeScreen() {
        print("🚀 Going back to welcome screen")
        
        // Simply dismiss this screen to go back to welcome
        dismiss(animated: true) {
            print("✅ Successfully returned to welcome screen!")
        }
    }
}
