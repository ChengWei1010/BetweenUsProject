//
//  Helper.swift
//  GoChat
//
//  Created by 鄭薇 on 2016/12/4.
//  Copyright © 2016年 LilyCheng. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseDatabase

class Helper{
    static let helper = Helper()
    
    func CreateAccountByEmail(NickName:String, Email: String, Password: String){
        FIRAuth.auth()?.createUser(withEmail: Email, password: Password, completion:{(user:FIRUser?, error) in
            if error != nil{
                print("create user error " + error!.localizedDescription)
                return
            }
            let newUser = FIRDatabase.database().reference().child("BetweenUsUsers").child(user!.uid)
            newUser.updateChildValues(["NickName":NickName, "Email":Email, "Pwd":Password, "id":"\(user!.uid)"])
            print("user created")
        })
    }

    
    func EnterChatRoomByEmail(NickName:String, Email: String, Password: String){
            FIRAuth.auth()?.signIn(withEmail: Email, password: Password) { (user:FIRUser?, error) in
            if error != nil{
                print("login error" + error!.localizedDescription)
                return
            }else{
                print("login successfully")
                print("your email is " + (user?.email)! )
                self.switchToNavigationViewController()
            }
        }
    }
    
    public func switchToNavigationViewController(){
        let storyboard = UIStoryboard(name:"Main", bundle:nil)
        let naviVC = storyboard.instantiateViewController(withIdentifier:"NavigationVC")
        let appDelegate = UIApplication.shared.delegate as!AppDelegate
        appDelegate.window?.rootViewController = naviVC
    }
}
