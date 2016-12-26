//
//  LoginViewController.swift
//  GoChat
//
//  Created by 鄭薇 on 2016/12/4.
//  Copyright © 2016年 LilyCheng. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class LoginViewController: UIViewController {
    
    @IBOutlet weak var Name: UITextField!
    @IBOutlet weak var InputEmail: UITextField!
    @IBOutlet weak var Password: UITextField!
    @IBOutlet weak var Enterbutton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // Set border color and width
        Enterbutton.layer.borderColor = UIColor.gray.cgColor
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print(FIRAuth.auth()?.currentUser)
        FIRAuth.auth()?.addStateDidChangeListener({(auth:FIRAuth, user:FIRUser?)in
//            if user!=nil{
//                print(user)
//            }else{
//                print(user)
//                print("UnAutherized")
//            }
        })
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func CreateAccount(_ sender: Any) {
        
        let Name = self.Name.text
        let InputEmail = self.InputEmail.text
        let Password = self.Password.text
        //Helper.helper.CreateAccountByEmail(NickName: Name!, Email: InputEmail!, Password: Password!)
        FIRAuth.auth()?.createUser(withEmail: InputEmail!, password: Password!, completion:{(user:FIRUser?, error) in
            if error != nil{
                print("create user error " + error!.localizedDescription)
                
                //創建失敗小視窗
                let alert = UIAlertController(title: "User Created error", message: "oops the account is already exist :(", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "create again", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            let newUser = FIRDatabase.database().reference().child("BetweenUsUsers").child(user!.uid)
            newUser.updateChildValues(["NickName":Name, "Email":InputEmail, "Pwd":Password, "id":"\(user!.uid)"])
            print("user created")
            
            //創建成功小視窗
            let alert = UIAlertController(title: "User Created Successfully", message: "hi " + Name! + " :)", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        })
    }
    @IBAction func EnterChatRoom(_ sender: Any) {
        let Name = self.Name.text
        let InputEmail = self.InputEmail.text
        let Password = self.Password.text
        Helper.helper.EnterChatRoomByEmail(NickName: Name!, Email: InputEmail!, Password: Password!)
        self.dismiss(animated: true, completion:nil)
        
        //self.performSegue(withIdentifier: "Login", sender: nil)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        super.prepare(for: segue, sender: sender)
//        let navVc = segue.destination as! UINavigationController // 1
//        let chatVc = navVc.viewControllers.first as! ChatViewController // 2
//        
//        chatVc.senderDisplayName = Name.text // 3
//    }
}
