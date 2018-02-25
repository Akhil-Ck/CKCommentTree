//
//  UCommentVCExtension.swift
//  Upcomer
//  Created by dxuser on 8/22/17.
//  Copyright © 2017 Upcomer. All rights reserved.


import Foundation
import  DZNEmptyDataSet

extension UMatchCommentVC: UITableViewDataSource, UITableViewDelegate,DZNEmptyDataSetSource,DZNEmptyDataSetDelegate{
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let nameAttributes = [NSForegroundColorAttributeName: UIColor.gray, NSFontAttributeName: UIFont(name:kProximaNovaRegular, size:15)]
        var title = NSMutableAttributedString(string: "This comment section is now closed", attributes: nameAttributes)
        
        if self.sessionStatus == "open"{
            title = NSMutableAttributedString(string: "There's no comments yet", attributes: nameAttributes)
        }else if self.sessionStatus == "closed" && self.session == "post-series" {
            title = NSMutableAttributedString(string: "This comment section opens as soon as the match is finished", attributes: nameAttributes)
        }
        return title
        
    }
     
     func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
           return #imageLiteral(resourceName: "no_comments")
     }
    
    
    //MARK : Tableview DS & Delegates
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if tableViewData.count == 0{
            return
        }
        
        if self.sessionStatus == "open"{
            if tableViewData[indexPath.row].level == 0{
                
                let indexofCurrentItem = level0Comments.index(of: tableViewData[indexPath.row])
                if indexofCurrentItem == level0Comments.count - 3{//Loads when reaches 3 rows before
                    fetchPaginatedComments()
                }
            }
        }
        
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == tableViewData.count{//Cell if particular session is closed
            let cell = UITableViewCell()
            cell.textLabel?.text = "This comment section is now closed"
            cell.textLabel?.textAlignment = .center
            cell.backgroundColor = UIColor.groupTableViewBackground
            cell.textLabel?.font = UIFont(name: kProximaNovaRegular, size: 15)
            return cell
        }
        
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "UCommentViewCell") as? UCommentCell
        cell?.uCommentCellDel = self
        cell?.currentPage = self.currentPage
        cell?.limitLevel = self.limitLevel
        cell?.tableViewData = self.tableViewData
        cell?.sessionStatus = self.sessionStatus
        cell?.commentObject = tableViewData[indexPath.row]
        cell?.populateData()
        
        return cell!
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if self.sessionStatus == "closed"{
            return  tableViewData.count == 0 ? 0 :tableViewData.count + 1

        }
        return  tableViewData.count
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        var cellHiddenStatus = false
        
        if sessionStatus == "closed"{
            
            if indexPath.row == tableViewData.count{
                return 40
            }else{
                let commentObject = tableViewData[indexPath.row]
                cellHiddenStatus = commentObject.isHidden
                let cell = tableView.cellForRow(at: indexPath) as? UCommentCell
                cellHiddenStatus = makeChangesWhenSetHeight(tableView: tableView,indexPath: indexPath)

                //cell?.populateData()
            }
            
            
        }else{
            let commentObject = tableViewData[indexPath.row]
            cellHiddenStatus = commentObject.isHidden
            let cell = tableView.cellForRow(at: indexPath) as? UCommentCell
            cellHiddenStatus = makeChangesWhenSetHeight(tableView: tableView,indexPath: indexPath)
            //cell?.populateData()
        }
        
        return cellHiddenStatus ? 0 : UITableViewAutomaticDimension
    }
    
    func makeChangesWhenSetHeight(tableView: UITableView,indexPath: IndexPath) -> Bool{
        
        let commentObject = tableViewData[indexPath.row]
        let cellHiddenStatus = commentObject.isHidden
        let cellChildHiddenStatus = commentObject.isChildHidden
        
        let cell = tableView.cellForRow(at: indexPath) as? UCommentCell
        cell?.toggleHidden.isHidden = false
        //cell?.populateData()
        
        
        if cellChildHiddenStatus{//if child cell is hidden
            switch commentObject.replyCount {
            case 0:
                cell?.toggleHidden.isHidden = true
            //cell?.toggleHidden.setTitle("No Replies", for: .normal)
            case 1:
                cell?.toggleHidden.setTitle("\(commentObject.replyCount) Reply", for: .normal)
            default:
                cell?.toggleHidden.setTitle("\(commentObject.replyCount) Replies", for: .normal)
            }
        }else{
            if commentObject.replyCount == 1{
                cell?.toggleHidden.setTitle("Hide Reply", for: .normal)
            }else{
                cell?.toggleHidden.setTitle("Hide Replies", for: .normal)
            }
        }
        cell?.layoutSubviews()
        cell?.tableViewData = self.tableViewData
        return cellHiddenStatus
    }
    
    func changeHiddenStatus(parentId: Int, status: Bool){
        
        for item in tableViewData{
            
            if item.parentId == parentId{
                if status == true{
                    changeHiddenStatus(parentId: item.id, status: status)
                }
                item.isHidden = status
            }
            
            if item.id == parentId{
                item.isChildHidden = status

            }
        }
        tableView.beginUpdates()
        tableView.endUpdates()
        reload()
    }
    
    
    func reload() {
        //Need to update two times else breakes ui
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
}

extension UMatchCommentVC:UCommentCellDelegate, UCommentPopUpDelegate{
    
     func didPressShare(cell: UCommentCell) {
          self.displayShareSheet("Shared from the Upcomer eSports app: " + cell.commentObject.comment)
     }
     
    func usernameTapped(cell: UCommentCell) {
        let indexPath = self.tableView.indexPath(for: cell)
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "ProfileViewController") as? ProfileViewController
         vc?.isPrivateProfile = false
        vc?.userId = self.tableViewData[(indexPath?.row)!].userId

        self.navigationController?.pushViewController(vc!, animated: true)
    }

    
    //MARK: UCommentCellDelegate
    func toggleHiddenStatus(cell: UCommentCell) {
        
        let indexPath = self.tableView.indexPath(for: cell)
        let parentId = tableViewData[(indexPath?.row)!].id
        
        changeHiddenStatus(parentId: parentId,status: cell.commentObject.isChildHidden)//MAke childs hidden for corresponding parentid
        
    }
    
    func editOnDoubleTap(cell: UCommentCell) {
        if cell.commentObject.isUserOwn{
            self.editComment(cell: cell)
        }
    }

    func redirectToNewThread(cell: UCommentCell) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "UMatchCommentVC") as? UMatchCommentVC
        vc?.entityId = "\(cell.commentObject.id)"
        vc?.currentPage = self.currentPage + 1
        //vc?.limitLevel +=  limitLevel
        vc?.isNewThread = true
        vc?.parentCommentObjectForThreading = cell.commentObject
        self.navigationController?.pushViewController(vc!, animated: true)
        //present(vc!, animated: true, completion: nil)
    }
    
    func insertReplies(cell: UCommentCell) {
        let indexPath = self.tableView.indexPath(for: cell)
        replyIndexPath = indexPath
        // let parentId = tableViewData[(indexPath?.row)!].id
        
        if cell.childData.count > 0{
            self.insertObject(data: cell.childData as [[String : AnyObject]], isComment: false, isMultipleReplies: true,paginationUrl:cell.commentObject.replyNextUrl)
        }
        //changeHiddenStatus(parentId: parentId,status: cell.commentObject.isChildHidden)//MAke childs hidden for corresponding parentid
    }
    
    func replyToComment(cell: UCommentCell) {
        
        if SessionHelper.sharedInstance.isVisitorFlow(){
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "UWelcomeViewController") as? UWelcomeViewController
            vc?.isFrom = "comments"

            vc?.isFromCommentSection = true
            vc?.isVisitorFlow = true
          self.navigationController?.pushViewController(vc!, animated: true)

          //   self.present(vc!, animated: true, completion: nil)
        }else{
            
            replyIndexPath = tableView.indexPath(for: cell)            
            let replyVc = UIViewController()
            let replyView = UCommentPopUp.instanceFromNib()
            replyView.uCommentPopUpDel = self
            replyView.isReplyComment = true
            replyView.sectionHeader.text = cell.comments.text
            replyView.commentId = cell.commentObject.id
            replyView.frame = replyVc.view.frame
            replyVc.view.addSubview(replyView)
            self.present(replyVc, animated: true, completion: nil)
            
        }
        
    }
    
    func didPressMore(cell:UCommentCell) {
        
        let actionSheetController = UIAlertController(title: "More", message: nil, preferredStyle: .actionSheet)
        actionSheetController.view.tintColor = kNavigationBarColor
        let titleFont = [NSFontAttributeName: UIFont(name: kProximaNovaSemiBold, size: 15.0)!]
        
        
        let titleAttrString = NSMutableAttributedString(string: "More", attributes: titleFont)
        
        actionSheetController.setValue(titleAttrString, forKey: "attributedTitle")
        
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action -> Void in
            
        }
        actionSheetController.addAction(cancelAction)
        
        let editAction = UIAlertAction(title: "Edit", style: .default) { action -> Void in
            self.editComment(cell: cell)
            
        }
        
        if cell.commentObject.isUserOwn{
            actionSheetController.addAction(editAction)
        }
        
        let reportAction = UIAlertAction(title: "Report", style: .default) { action -> Void in
            self.doReport(params:["comment_id":cell.commentObject.id as AnyObject])
        }
        
        if !cell.commentObject.isUserOwn{
            actionSheetController.addAction(reportAction)
        }
        
        self.present(actionSheetController, animated: true, completion: nil)
        
        //showToolTip(yPosition: cell.frame.origin.y)
    }
    
    //MARK: UCommentPopUpDelegate
    func dismissPopUpCommentView(data:[String:AnyObject]) {
        
        if data.count > 0{
            self.insertObject(data: [data], isComment: false, paginationUrl: "")
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func updateComment(data: [String : AnyObject]) {
        //self.tableView.reloadData()
        UIView.performWithoutAnimation({
            let loc = tableView.contentOffset
            tableView.reloadSections(NSIndexSet(index: 0) as IndexSet, with: UITableViewRowAnimation.none)
            tableView.contentOffset = loc
        })
        self.dismiss(animated: true, completion: nil)
    }
    
}

extension Array {
    mutating func rearrange(from: Int, to: Int) {
        insert(remove(at: from), at: to)
    }
}
