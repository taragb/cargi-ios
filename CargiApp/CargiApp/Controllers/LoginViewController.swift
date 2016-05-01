//
//  LoginViewController.swift
//  Cargi
//
//  Created by Edwin Park on 4/30/16.
//  Copyright © 2016 Cargi. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailTextField: UITextField!
    lazy var db = AzureDatabase.sharedInstance

    override func viewWillAppear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        super.viewWillDisappear(animated)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.emailTextField.delegate = self
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == emailTextField {
            textField.resignFirstResponder()
            print("Done typing")
            print("Should log in now")
            // should check whether the email exists or not
            return false
        }
        return true
    }
    
    @IBAction func loginButtonClicked(sender: UIButton) {
        let email = emailTextField.text
        if (email == nil) {
            // TODO: some error message or red error text under the login name
            // "PLEASE LOGIN?"
            
        } else {
            let emailString = email!
            if (emailString == "") { // TODO: check if email is a valid format, or valid email. X@Y.Z - external API?
                // TODO: some error message or red error text under the login name
                // "PLEASE INPUT A VALID EMAIL"
                
            } else {
                db.emailExists(emailString) { (status, exists) in
                    if (!exists) { // if email doesn't exist, user needs to sign up
                        // TODO: some error message or red error text under the login name
                        // "Looks like you don't have an account yet" ??
                    } else {
                        // email exists, but not sure if this actually is the right user
                        // can call checkEmailLogin, which returns if the email is correct or not. (currently just matching the userID, which is based on deviceID)
                        self.db.checkEmailLogin(emailString) { (status, correct) in
                            if (correct) {
                                // continue to the home screen
                                
                            } else {
                                // print error message about incorrect email login
                            }
                        }
                    }
                }
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
    }
    */

}
