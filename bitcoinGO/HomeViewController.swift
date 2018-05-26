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
        
        loginManager.logIn(readPermissions: [ .publicProfile, .email, .userLocation], viewController: self) { LoginResult in
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
                }
            }
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if AccessToken.current != nil {
            // User is logged in, use 'accessToken' here.
            print("user ", AccessToken.current?.userId as Any, "is logged in")
        }
        
    }
    
    
    
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
        // some code here
        print("loginButtonDidCompleteLogin")
        let credential = FacebookAuthProvider.credential(withAccessToken: (AccessToken.current?.authenticationToken)!)
        
        Auth.auth().signInAndRetrieveData(with: credential) { (authResult, error) in
            if error != nil {
                print(error?.localizedDescription as Any)
                return
            }
            // User is signed in
        }
        
        showEmailAddress()
        
    }
    func showEmailAddress() {
        let accessToken = AccessToken.current
        
        guard let accessTokenString = accessToken?.authenticationToken else { return }
        
        let credentials = FacebookAuthProvider.credential(withAccessToken: accessTokenString)
        
        Auth.auth().signInAndRetrieveData(with: credentials) { (user, error) in
            if error != nil {
                print("ya fucked up", error as Any)
                return
            }
            print("successfully logged in with", user as Any)
        }
        
    }

    override func viewDidAppear(_ animated: Bool) {
        // Segue to MapViewController if user is logged in
        if AccessToken.current != nil {
            performSegue(withIdentifier: "pushToMapView", sender: self)
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: LoginButton) {
        // some code here
        
    }

}

