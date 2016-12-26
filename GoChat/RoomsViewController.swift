//
//  RoomsViewController.swift
//  GoChat
//
//  Created by 鄭薇 on 2016/12/19.
//  Copyright © 2016年 LilyCheng. All rights reserved.
//
import Foundation
import UIKit
import Firebase

enum Section: Int {
    case createNewChannelSection = 0
    case currentChannelsSection
}


class RoomsViewController: UIViewController {
    
    // MARK: Properties
    var senderDisplayName: String?
    var newRoomTextField: UITextField?
    
    private lazy var roomRef: FIRDatabaseReference = FIRDatabase.database().reference().child("rooms")
    
    // MARK: TextField
    @IBOutlet weak var InputRoomName: UITextField!    
    @IBOutlet weak var InputRoomNum: UITextField!
    
    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = senderDisplayName
        observeRooms()
    }
    deinit {
        if let refHandle = roomRefHandle {
            roomRef.removeObserver(withHandle: refHandle)
        }
    }
    
    // MARK :Actions
    @IBAction func Logout(_ sender: Any) {
        print("User logged out")
        do{
            try FIRAuth.auth()?.signOut()
        }catch let error{
            print(error)
        }
        print(FIRAuth.auth()?.currentUser)
        //Create a main storyboard instance
        let storyboard = UIStoryboard(name : "Main", bundle: nil)
        
        //From main storyboard instantiate a View controller
        let LoginVC = storyboard.instantiateViewController(withIdentifier:"LoginVC")as!LoginViewController
        //Get the app delegate
        let appDelegate = UIApplication.shared.delegate as!AppDelegate
        //Set Login Conteoller as root view controller
        appDelegate.window?.rootViewController = LoginVC
    }
    
    @IBAction func NewRoom(_ sender: Any) {
        let randomRoomNum:UInt32 = arc4random_uniform(9999) //亂數產生四位數房號
        let newRoomRef = roomRef.childByAutoId()            //firebase裡的reference
        let roomName = self.InputRoomName.text
        
        let roomItem = ["RoomNum": randomRoomNum]
        
        newRoomRef.setValue(roomItem)
        print("room ref is " + String(describing: newRoomRef))
        print("room name is " + roomName!)
        print("room num is " + String(describing: randomRoomNum))
    }

    @IBAction func EnterRoom(_ sender: Any) {
//        let inputRoomNum = self.InputRoomNum.text
//        let myRoom = ["RoomNum":inputRoomNum]
//        self.performSegue(withIdentifier: "ShowRoom", sender: myRoom)
        print("enter")
    }
    
    // MARK: Firebase related methods
    private func observeRooms() {
        // We can use the observe method to listen for new rooms being written to the Firebase DB
        
        roomRefHandle = roomRef.observe(.childAdded, with: { (snapshot) -> Void in
            let roomData = snapshot.value as! Dictionary<String, AnyObject>
            let id = snapshot.key
            if let name = roomData["name"] as! String!, name.characters.count > 0 {
                print("finding room")
                self.rooms.append(Room(id: id, roomNum: "1"))
                //self.tableView.reloadData()
            } else {
                print("Error! Could not decode channel data")
            }
        })
    }
    
    // MARK: Navigation
    override func prepare(for segue:UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let room = sender as? Room {
            let chatVc = segue.destination as! ChatViewController
            chatVc.senderDisplayName = senderDisplayName
            chatVc.room = room
            chatVc.roomRef = roomRef.child(room.id)
        }
    }
    
}
