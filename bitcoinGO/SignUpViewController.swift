//
//  SignUpViewController.swift
//  
//
//  Created by Jason Crouse on 5/24/18.
//

import UIKit
import SinchVerification
import Firebase


class SignUpViewController: UIViewController {
    @IBOutlet weak var email: UITextField!
    
    @IBOutlet weak var password: UITextField!
    
    @IBOutlet weak var phoneNumber: UITextField!
    
    @IBOutlet weak var verificationCode: UITextField!
    
    @IBOutlet weak var status: UILabel!
    
    
    @IBOutlet weak var emailSignUp: UIButton!
    @IBAction func emailSignUp(_ sender: Any) {
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
        
    }
    
    
    var verification : Verification!
    var applicationKey = "3924773d-fb21-4f1b-af25-f460e911c343"
    

    @IBAction func smsVerification(_ sender: Any) {
        self.disableUI(true);
        
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber.text!, uiDelegate: nil) { (verificationID, error) in
            if let error = error {
                self.status.text = (error.localizedDescription)
                print(error.localizedDescription)
                return
            }
            // save verification ID
            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            
        }
        
    }
    
    @IBAction func verify(_ sender: Any) {
        
        // Restore verification ID
        let verificationID = UserDefaults.standard.string(forKey: "authVerificationID")
        
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
            self.status.text = "Verified"
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
