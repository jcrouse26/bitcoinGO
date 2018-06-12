//
//  HomeViewController.swift
//  bitcoinGO
//
//  Created by Jason Crouse on 5/17/18.
//  Copyright © 2018 Jason Crouse. All rights reserved.
//

import UIKit
import FacebookLogin
import FacebookCore
import Firebase

class HomeViewController: UIViewController, LoginButtonDelegate {
    
    @IBOutlet weak var textField: UITextField!
   
    @IBAction func action(_ sender: Any) {
        
    }
    
    @IBAction func didTapFacebookButton(_ sender: Any) {
        let loginManager = LoginManager()
        
        loginManager.logIn(readPermissions: [ .publicProfile, .email], viewController: self) { LoginResult in
            switch LoginResult {
            case .failed(let error):
                print(error)
            case .cancelled:
                print("user login cancelled")
            case .success( _, _, _):
                print(" ")
                let credential = FacebookAuthProvider.credential(withAccessToken: (AccessToken.current?.authenticationToken)!)
                Auth.auth().signInAndRetrieveData(with: credential) { (authResult, error) in
                    if error != nil {
                        print(error?.localizedDescription as Any)
                        return
                    }
                    // User is signed in
                    print("success, user signed in")
					self.performSegue(withIdentifier: "pushToMapView", sender: self)
                }
            }
        }
    }
    
    
    override func viewDidLoad() {
		
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
		
		checkIfUserIsSignedIn()
        
    }
    
    
    
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
        let credential = FacebookAuthProvider.credential(withAccessToken: (AccessToken.current?.authenticationToken)!)
        
        Auth.auth().signInAndRetrieveData(with: credential) { (authResult, error) in
            if error != nil {
                print(error?.localizedDescription as Any)
                return
            }
            // User is signed in
        }
        
        logIntoFirebaseWithFacebookToken()
        
    }
    func logIntoFirebaseWithFacebookToken() {
        let accessToken = AccessToken.current
		
        guard let accessTokenString = accessToken?.authenticationToken else { return }
        
        let credentials = FacebookAuthProvider.credential(withAccessToken: accessTokenString)
        
        Auth.auth().signInAndRetrieveData(with: credentials) { (user, error) in
            if error != nil {
				print("Error loggin in: ", error as Any)
                return
			}
        }
    }

    override func viewDidAppear(_ animated: Bool) {
		print("view is appearing...")
		
        // Segue to MapViewController if user is logged in
        if Auth.auth().currentUser != nil {
            performSegue(withIdentifier: "pushToMapView", sender: self)
		} else {
			print("user not logged into firebase")
		}
    }
    
    func loginButtonDidLogOut(_ loginButton: LoginButton) {
        // some code here
        
    }
	
	private func checkIfUserIsSignedIn() {
		Auth.auth().addStateDidChangeListener { (auth, user) in
			if user != nil {
				// user is signed in
				print("user is signed in")
				// go to feature controller
				self.performSegue(withIdentifier: "pushToMapView", sender: self)
			} else {
				// user is not signed in
				// go to login controller
				print("user is not signed in")
			}
		}
	}

}

