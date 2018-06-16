//
//  SignUpViewController.swift
//  
//
//  Created by Jason Crouse on 5/24/18.
//

import UIKit
import Firebase


class SignUpViewController: UIViewController {
    
    @IBOutlet weak var phoneNumber: UITextField!
    @IBOutlet weak var verificationCode: UITextField!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var verifyButton: UIButton!
    
    var applicationKey = "3924773d-fb21-4f1b-af25-f460e911c343"

    @IBAction func smsVerification(_ sender: Any) {
        self.disableUI(true);
        
        PhoneAuthProvider.provider().verifyPhoneNumber("+1\(phoneNumber.text!)", uiDelegate: nil) { (verificationID, error) in
            if let error = error {
                self.status.text = (error.localizedDescription)
                print(error.localizedDescription)
                return
            }
            // save verification ID
			print("1+\(self.phoneNumber.text!)", "== phone number input")
            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            self.phoneNumber.isHidden = true
            self.nextButton.isHidden = true
            self.verifyButton.isHidden = false
            self.verificationCode.isHidden = false
        }
        
    }
    
    @IBAction func didTapVerify(_ sender: Any) {
        verify()
    }
    
    
    func verify() {
        
        // If user has been verified before, enter game
        if UserDefaults.standard.bool(forKey: "phoneVerified") == true {
            print("user already verified via phone")
            self.performSegue(withIdentifier: "pushToMapView", sender: self)
        }
        
        // Restore verification ID
        let verificationID = UserDefaults.standard.string(forKey: "authVerificationID")
        
        // If nil return
        if verificationID == nil {
            return
        }
        
        // Sign in with verification ID and user-inputted code
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID!,
            verificationCode: verificationCode.text!)
        
        Auth.auth().signInAndRetrieveData(with: credential) { (authResult, error) in
            if let error = error {
                self.status.text = error.localizedDescription
                print(error.localizedDescription)
                return
            }
            // User is signed in
            UserDefaults.standard.set(true, forKey: "phoneVerified")
            self.performSegue(withIdentifier: "pushToMapView", sender: self)
        }
    }
    
    func disableUI(_ disable: Bool){
    
        if (disable) {
            phoneNumber.resignFirstResponder()
            let delayTime =
                DispatchTime.now() +
                    Double(Int64(30 * Double(NSEC_PER_SEC)))
                    / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(
                deadline: delayTime, execute:
                { () -> Void in
                    self.disableUI(false)
            })
        }
        else{
            self.phoneNumber.becomeFirstResponder();
        }
        self.phoneNumber.isEnabled = !disable;
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        verificationCode.isHidden = true
        verifyButton.isHidden = true
        
        UserDefaults.standard.set(false, forKey: "phoneVerified")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        verify()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // Should we want to do email verification:
    
    /*@IBAction func emailSignUp(_ sender: Any) {
     let actionCodeSettings = ActionCodeSettings()
     actionCodeSettings.url = URL(string: "https://wt9w4.app.goo.gl/eNh4")
     // The sign-in operation has to always be completed in the app.
     actionCodeSettings.handleCodeInApp = true
     actionCodeSettings.setIOSBundleID(Bundle.main.bundleIdentifier!)
     actionCodeSettings.setAndroidPackageName("com.example.android",
     installIfNotAvailable: false, minimumVersion: "12")
     
     Auth.auth().sendSignInLink(toEmail:email.text!, actionCodeSettings: actionCodeSettings) { error in
     // ...
     if let error = error {
     self.status.text = error.localizedDescription
     print(error.localizedDescription)
     return
     }
     // The link was successfully sent. Inform the user.
     // Save the email locally so you don't need to ask the user for it again
     // if they open the link on the same device.
     UserDefaults.standard.set(self.email.text, forKey: "Email")
     self.status.text = "Check your email for link"
     print("check your email for link")
     // ...
     }
     
     }*/
}
