//
//  UCommentPopUp.swift
//  Upcomer
//
//  Created by dxuser on 8/10/17.
//  Copyright © 2017 Upcomer. All rights reserved.
//

import Foundation


import UIKit

protocol UCommentPopUpDelegate {
    //func presentInputCommentView()
    func dismissPopUpCommentView(data:[String:AnyObject])
    func updateComment(data:[String:AnyObject])
}

class UCommentPopUp: UIView, UITextViewDelegate {
     let indicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)

    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var commentTextView: UITextView!
    @IBOutlet weak var titleHeader: UILabel!
    @IBOutlet weak var sectionHeader: UILabel!
    var commentId :Int?//Reply comment parent id
    var objectId = ""
    var session = "pre-series"
    var commentObject:UCommentData?
    var isNews:Bool = false
     var isPosting:Bool = false
    
     @IBOutlet weak var commentHeader: UIView!
    @IBOutlet weak var constraintToTop: NSLayoutConstraint!
    var editText = ""
    
    var placeHolderText = ""
    
    var isEdit = false{
        didSet{
            constraintToTop.constant = isEdit ? -50 : 20
            commentHeader.isHidden = isEdit
        }
        
    }
    var isReplyComment : Bool = false{
        didSet{
            
            if isEdit{
                titleHeader.text = "Edit Reply"
                
            }else{
                placeHolderText = isReplyComment ? "Your reply..." : "Your comment..."
                titleHeader.text = isReplyComment ? "Post Reply" : "Post Comment"
            }
        }
        
    }
    var uCommentPopUpDel:UCommentPopUpDelegate?
    
    override func awakeFromNib() {
        
        topView.backgroundColor = kNavigationBarColor
        commentTextView.text = isEdit ? editText : placeHolderText
        addToolBar(textField: commentTextView)
        commentTextView.becomeFirstResponder()
     commentTextView.autocorrectionType = .yes
     
     func setLoadingIndicator(){
          indicator.center = self.center
          indicator.hidesWhenStopped = true
          indicator.color = kDarkRed
          if indicator.isDescendant(of: self) {
               indicator.removeFromSuperview()
          }
          self.addSubview(indicator)
     }


     
    }
    
    class func instanceFromNib() -> UCommentPopUp{
        
        let nib = UINib(nibName: "UCommentPopUp", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as? UCommentPopUp
        
        return nib!
    }
    
    
    
    // MARK : UITextViewDelegate
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        
        self.commentTextView.textColor = UIColor.white
        
        if(self.commentTextView.text == placeHolderText) {
            self.commentTextView.text = ""
        }
        
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if(commentTextView.text == "") {
            self.commentTextView.text = placeHolderText
            self.commentTextView.textColor = UIColor.white
        }
    }

    // MARK : Actions
    @IBAction func didPressCancel(_ sender: Any) {
        
        commentTextView.endEditing(true)
        uCommentPopUpDel?.dismissPopUpCommentView(data:[:])
        
    }
    
    @IBAction func donePressed(_ sender:AnyObject) {
    indicator.startAnimating()
     if isPosting == true{
          return
     }
     isPosting = true
        if isEdit{
            editAPI()
            return
        }
        
        var param = ["comment_text": commentTextView.text,
                     "object_type": "series",
                     "object_id": self.objectId,
                     "session": session] as [String : Any]
        if isNews{
            param = ["comment_text": commentTextView.text,
                     "object_type": "news",
                     "object_id": self.objectId] as [String : Any]
        }
        
        if isReplyComment{
            param = ["comment_text": commentTextView.text,
                     "reply_to": commentId!] as [String : Any]
        }
        
        
        UCommentHelper.sharedInstance.postComment(param as [String : AnyObject], isReply: self.isReplyComment) { (error, response) in
          
            if error == nil{
               self.indicator.stopAnimating()
                self.endEditing(true)
               self.isPosting = false
                self.uCommentPopUpDel?.dismissPopUpCommentView(data:response!)
            }
        }
    }
    
    func editAPI(){
        let param = ["comment_text": commentTextView.text,
                     "comment_id": self.commentId ?? 0
                     ] as [String : Any]
        UCommentHelper.sharedInstance.request(param as [String : AnyObject], url: keditComment) { (error, response) in
            if error == nil{
               self.indicator.stopAnimating()

                self.endEditing(true)
                self.isPosting = false

                self.commentObject?.comment = self.commentTextView.text
                self.uCommentPopUpDel?.updateComment(data:response!)
            }
        }
    }
}


extension UCommentPopUp {
    
    func addToolBar(textField: UITextView) {
       // let toolBar = UIToolbar()
       // toolBar.backgroundColor = kNavigationBarColor
       // toolBar.barTintColor = kNavigationBarColor
       // toolBar.barStyle = .default
       // toolBar.isTranslucent = true
        //toolBar.tintColor = UIColor.white
        
        
      //  let doneButton = UIBarButtonItem(title: "Post", style: .done, target: self, action: #selector(donePressed))
       // if let font = UIFont(name: kProximaNovaSemiBold, size: 15) {
       //     doneButton.setTitleTextAttributes([NSFontAttributeName:font], for: .normal)
      //  }
//        let cancelButton = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(cancelPressed))
//        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
//        
//        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
//        
//        
//        toolBar.isUserInteractionEnabled = true
//        toolBar.sizeToFit()
//        
//        textField.delegate = self
//        textField.inputAccessoryView = toolBar
    }
    
    func cancelPressed() {
        self.endEditing(true)
    }
}
