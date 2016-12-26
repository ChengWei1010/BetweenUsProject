//
//  ChatViewController.swift
//  GoChat
//
//  Created by 鄭薇 on 2016/12/4.
//  Copyright © 2016年 LilyCheng. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import MobileCoreServices
import AVKit
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

class ChatViewController: JSQMessagesViewController {
    var messages = [JSQMessage]()
    var nickNamesDict = [NSAttributedString]()    

    //var roomRef: FIRDatabaseReference?
    //private lazy var messageRef: FIRDatabaseReference = self.roomRef!.child("薇的訊息")
    var messageRef = FIRDatabase.database().reference().child("BetweenUsChats")
    fileprivate lazy var storageRef: FIRStorageReference = FIRStorage.storage().reference(forURL: "gs://tripgif-b205b.appspot.com")

    @IBOutlet weak var myName: UIBarButtonItem!
    
    override func viewDidLoad() {
        self.scrollToBottom(animated: true)
        super.viewDidLoad()
        // No avatars
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        if let currentUser = FIRAuth.auth()?.currentUser{
            self.senderId = currentUser.uid
            if currentUser.isAnonymous == true
            {
                self.senderDisplayName = "anonymous"
            }else{
                self.senderDisplayName = currentUser.email!
            }
        }
        observeUsers(id: self.senderId)
        observeMessages()
    }
    
    //偵測打字的泡泡 indicate typing-----------------------------------------
//    override func textViewDidChange(_ textView: UITextView) {
//        super.textViewDidChange(textView)
//        // If the text is not empty, the user is typing
//        print(textView.text != "")
//        //isTyping = textView.text != ""
//    }
//    //private lazy var userIsTypingRef: FIRDatabaseReference = self.messageRef.child("typingIndicator").child(self.senderId) // 1 chatchat
//    private lazy var userIsTypingRef: FIRDatabaseReference = FIRDatabase.database().reference().child("typingIndicator") // 1 mine
//    
//    private var localTyping = false // 2
//    var isTyping: Bool {
//        get {
//            return localTyping
//        }
//        set {
//            // 3
//            localTyping = newValue
//            userIsTypingRef.child(self.senderId).setValue(newValue)
//        }
//    }
//    private func observeTyping() {
//        let typingIndicatorRef = FIRDatabase.database().reference().child("typingIndicator")
//        userIsTypingRef = typingIndicatorRef.child(senderId)
//        userIsTypingRef.onDisconnectRemoveValue()
//    }
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        observeTyping()
//    }
    //---------------------------------------------------------------------
    
    func observeUsers(id: String){
        self.scrollToBottom(animated: true)
        FIRDatabase.database().reference().child("BetweenUsUsers").child(id).observe(FIRDataEventType.value){
            //印出新成員 讀出新成員
            (snapshot: FIRDataSnapshot) in
            if let dict = snapshot.value as? [String:String]
            {
                //取出成員資料
                //print(dict)
                let myid = String(self.senderId)
                if dict["id"] == myid{
                    //取出我的暱稱
                    let myname = dict["NickName"]
                    //print("myname is " + myname!)
                    self.myName.title = myname
                }
            }
        }
    }
    
    func observeMessages(){ //Pooling data，把message轉成JSQMessage型態來顯示
        
        messageRef.observe(FIRDataEventType.childAdded, with: {snapshot in
            if let dic = snapshot.value as? [String: AnyObject]{
                let mediaType = dic["MediaType"] as! String //以String的型態傳上server
                let senderId = dic["senderId"] as! String
                let senderName = dic["senderName"] as! String
                //print(dic)
                
                self.observeUsers(id: senderId)
                
                switch mediaType{
                case "indicater":
                    let indicater = dic["indicater"] as! String
                    self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, text: indicater))

                case "TEXT":
                    let text = dic["text"] as! String
                    self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, text: text))
                    
                case "PHOTO":
                    let fileUrl = dic["fileUrl"] as! String
                    let url = NSURL(string: fileUrl) //把url轉成NSURL
                    let data = NSData(contentsOf: url as! URL)
                    let picture = UIImage(data: data as! Data)
                    let photo = JSQPhotoMediaItem(image: picture)
                    self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, media: photo))
                    
                    if self.senderId == senderId{//bubble tail turn right
                        photo?.appliesMediaViewMaskAsOutgoing = true
                    }else{//bubble tail turn left
                        
                        photo?.appliesMediaViewMaskAsOutgoing = false
                    }
                    
                case "VIDEO":
                    let fileUrl = dic["fileUrl"] as! String
                    let video = NSURL(string: fileUrl)
                    let videoItem = JSQVideoMediaItem(fileURL: video as URL!, isReadyToPlay: true)
                    self.messages.append(JSQMessage(senderId: senderId, displayName: senderName, media: videoItem))
                    
                    if self.senderId == senderId{//bubble tail turn right
                        videoItem?.appliesMediaViewMaskAsOutgoing = true
                    }else{//bubble tail turn left
                        
                        videoItem?.appliesMediaViewMaskAsOutgoing = false
                    }
                    
                default:
                    print("unknown data type")
                }
                
                self.collectionView.reloadData()
                self.scrollToBottom(animated: true)
            }
        })
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        let newMessage = messageRef.childByAutoId()
        let messageData = ["text": text, "senderId": senderId, "senderName": senderDisplayName, "MediaType": "TEXT"] //把訊息存在server上
        newMessage.setValue(messageData)
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        self.finishSendingMessage() //讓傳送框的字不見
        self.scrollToBottom(animated: true)
        //isTyping = false
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {//選取要上傳的照片檔案
        print("didPressAccessoryButton")
        //跑出選擇影片的對話框
        let sheet = UIAlertController(title: "Media Messages", message: "Please select a media", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        let cancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel){
            (UIAlertAction) in}
        
        let photoLibrary = UIAlertAction(title: "Photo Library", style: UIAlertActionStyle.default){(alert: UIAlertAction) in
            self.getMediaFrom(type: kUTTypeImage)
        }
        
        let videoLibrary = UIAlertAction(title: "Video Library", style: UIAlertActionStyle.default){(alert: UIAlertAction) in
            self.getMediaFrom(type: kUTTypeMovie)
        }
        
        sheet.addAction(photoLibrary)
        sheet.addAction(videoLibrary)
        sheet.addAction(cancel)
        self.present(sheet, animated:true, completion: nil)
    }
    
    func getMediaFrom(type: CFString){
        print(type)
        let mediaPicker = UIImagePickerController()
        mediaPicker.delegate = self
        mediaPicker.mediaTypes = [type as String] //因為CFString不是string，所以要判斷時要轉成string型態
        self.present(mediaPicker, animated: true, completion: nil)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData!{
        return messages[indexPath.item]
    }
    //顯示訊息的方框
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        let bubbleFactory = JSQMessagesBubbleImageFactory()//用來產生bubble的method
        if message.senderId == self.senderId{ //如果訊息的id跟chatview裡的sender id一樣
            
            return bubbleFactory?.outgoingMessagesBubbleImage(with: UIColor(red:0.72, green:0.71, blue:0.71, alpha:1.0))
        }else{ //incoming message
            
            return bubbleFactory?.incomingMessagesBubbleImage(with: UIColor(red:0.77, green:0.33, blue:0.22, alpha:1.0))
        }
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! { //頭貼
        return nil
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int{
        print("number of item:\(messages.count)")
        return messages.count
    }
    //Create cells to display messages
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath as IndexPath) as! JSQMessagesCollectionViewCell
        return cell
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        print("didTapMessageBubbleAtIndexPath: \(indexPath.item)")
        let message = messages[indexPath.item]
        if message.isMediaMessage{ //如果是影片就讓它播放
            if let mediaItem = message.media as? JSQVideoMediaItem{
                let player = AVPlayer(url: mediaItem.fileURL)
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player //告訴AVPlayer要播哪部影片(player)
                self.present(playerViewController, animated: true, completion: nil)
            }
        }
    }
    
    //名字標籤小泡泡
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return 15
    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView?, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString? {
        let message = messages[indexPath.item]
        switch message.senderId {
        case senderId:
            return nil
        default:
            guard let senderDisplayName = message.senderDisplayName else {
                assertionFailure()
                return nil
            }
            return NSAttributedString(string: senderDisplayName)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func logoutDidTapped(_ sender: AnyObject) {
        do{
            try FIRAuth.auth()?.signOut()
        }catch let error{
            print(error)
        }        
        //Create a main storyboard instance
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        //From main storyboard instantiate a View controller
        let LogInVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as! LoginViewController
        //Get the app delegate
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        //Set Login View Controller as root view controller
        appDelegate.window?.rootViewController = LogInVC
    }
    
    func sendMedia(picture: UIImage?, video: NSURL?){ //把照片send然後存到Firebse Database
        print(picture)
        print(FIRStorage.storage().reference()) //印出Firebase Storage的URL
        if let picture = picture{ //Media是照片
            let filePath = "\(FIRAuth.auth()!.currentUser!)/\(NSDate.timeIntervalSinceReferenceDate)" //用目前使用者和時間來區別不同的filePath
            print(filePath)
            let data = UIImageJPEGRepresentation(picture, 0.1)// return image as JPEG, 1表示部壓縮，把UIImage轉成NSData
            let metadata = FIRStorageMetadata()
            metadata.contentType = "image/jpg"
            FIRStorage.storage().reference().child(filePath).put(data!, metadata: metadata){(metadata, error) in //child:存照片的地方, put:上傳照片到storage
                if error != nil{
                    print(error?.localizedDescription)
                    return
                }
                //print(metadata)
                let fileUrl = metadata!.downloadURLs![0].absoluteString //!:not nil, Get the URL string from URL
                let newMessage = self.messageRef.childByAutoId()
                let messageData = ["fileUrl": fileUrl, "senderId": self.senderId, "senderName": self.senderDisplayName, "MediaType": "PHOTO"]
                newMessage.setValue(messageData)
            }
        }else if let video = video{
            let filePath = "\(FIRAuth.auth()!.currentUser!)/\(NSDate.timeIntervalSinceReferenceDate)" //用目前使用者和時間來區別不同的filePath
            print(filePath)
            let data = NSData(contentsOf: video as URL)// return video as NSData
            let metadata = FIRStorageMetadata()
            metadata.contentType = "vedio/mp4"
            FIRStorage.storage().reference().child(filePath).put(data! as Data, metadata: metadata){(metadata, error) in //child:存照片的地方, put:上傳照片到storage
                if error != nil{
                    print(error?.localizedDescription)
                    return
                }
                //print(metadata)
                let fileUrl = metadata!.downloadURLs![0].absoluteString //!:not nil, Get the URL string from URL
                let newMessage = self.messageRef.childByAutoId()
                let messageData = ["fileUrl": fileUrl, "senderId": self.senderId, "senderName": self.senderDisplayName, "MediaType": "VIDEO"]
                newMessage.setValue(messageData)
            }
            
        }
        
    }
    
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: AnyObject]) {
        print("finish pickig")
        //取得圖片
        print(info)
        if let picture = info[UIImagePickerControllerOriginalImage] as? UIImage{//訊息是照片
            // let photo = JSQPhotoMediaItem(image: picture) //轉成JSQMessage
            //messages.append(JSQMessage(senderId: senderId, displayName: senderDisplayName, media: photo)) //讓message呈現照片
            sendMedia(picture: picture, video: nil)
        }
        else if let video = info[UIImagePickerControllerMediaURL] as? NSURL{//訊息是影片
            //let videoItem = JSQVideoMediaItem(fileURL: video as URL!, isReadyToPlay: true)
            //messages.append(JSQMessage(senderId: senderId, displayName: senderDisplayName, media: videoItem))
            //sendMedia(picture: nil, video: video)
        }
        
        self.dismiss(animated: true, completion: nil) //照片選完相簿就消失(imagePicker)
        collectionView.reloadData() //每次重新整理，讓id可以++
    }
}
