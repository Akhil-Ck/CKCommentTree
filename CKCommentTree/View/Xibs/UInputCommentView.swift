
//
//  UInputCommentView.swift
//  Upcomer
//
//  Created by dxuser on 8/10/17.
//  Copyright © 2017 Upcomer. All rights reserved.
//

import Foundation

import UIKit

protocol UInputCommentViewDelegate {
    func presentInputCommentView()
}

class UInputCommentView: UIView, UITextFieldDelegate {
    
    var uInputCommentViewDel:UInputCommentViewDelegate?
    
     @IBOutlet weak var commentBottomText: UITextField!
    class func instanceFromNib() -> UInputCommentView{
        
        let nib = UINib(nibName: "UInputCommentView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as? UInputCommentView
        
        return nib!
    }
    
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        uInputCommentViewDel?.presentInputCommentView()
        textField.endEditing(true)
    }
    
}
