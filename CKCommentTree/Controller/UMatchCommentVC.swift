//
//  UMatchCommentVC.swift
//  Upcomer
//
//  Created by dxuser on 8/8/17.
//  Copyright © 2017 Upcomer. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

class UMatchCommentVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var commentText: UITextField!
    
    @IBOutlet weak var tableViewY: NSLayoutConstraint!
    @IBOutlet weak var tableViewBottom: NSLayoutConstraint!
    
    var replyIndexPath: IndexPath?
    var uCommentInstance = UCommentTree()
    var tableViewData:[UCommentData] = []
    var parentCommentObjectForThreading:UCommentData = UCommentData()
    var responseData:[[String:Any]] = []
    var replyDataFromPN :[String:Any] = [:]
    
    var session:String = "post-series"
    var paginatedUrl:String = ""
    var limit:String = "&limit=10"
    var sessionStatus:String = ""
    var entityId:String = ""

    var totalCount:Int = 0 // for pagination
    var currentPage:Int = 0 //For threading if 0 no threading
    var limitLevel:Int = 8
    var level0Comments:[UCommentData] = [] // This is for 0 th level pagination

    var refresher:UIRefreshControl!
    
    var didPaginationEnd:Bool = false
    var isNewThread:Bool = false// Equal to true, when new thread starts 
    var isFromPush:Bool = false
    var isFromPorfile:Bool = false
    var userId:Int?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        Utils().flurryLogEvent(COMMENTS)
        self.tableView.allowsMultipleSelection = true
        self.tableView.rowHeight = UITableViewAutomaticDimension
        tableViewY.constant = -60
        tableViewBottom.constant = 5
        
        if isFromPush{
            fetchInitialCommentsIfFromPN()
            addBackButton()
        }else{
            if isNewThread{
                tableViewY.constant = 15

                fetchThreadComments()
                addBackButton()
            }
            else{
                fetchInitialComments()
                tableViewY.constant = 15
                tableViewBottom.constant = 46
            }
        }
        setupRefresher()
     
     let nib1 = UINib(nibName: "UCommentViewCell", bundle: nil)
     tableView.register(nib1, forCellReuseIdentifier: "UCommentViewCell")


    }
    
    func setupRefresher(){
        refresher = UIRefreshControl()
        self.tableView.alwaysBounceVertical = true
        self.refresher.tintColor = kDarkRed
        self.refresher.addTarget(self, action: #selector(loadData), for: .valueChanged)
        self.tableView.addSubview(refresher)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK : Methods
    func loadData(){//refresh Data
        
        self.tableView.emptyDataSetSource = nil
        self.tableView.emptyDataSetDelegate = nil
        tableViewY.constant = -60
        tableViewBottom.constant = 5
        
        if isFromPush{
            fetchInitialCommentsIfFromPN()
            addBackButton()
        }else{
            if isNewThread{
                tableViewY.constant = 46

                fetchThreadComments()
                addBackButton()
            }
            else{
                fetchInitialComments()
                tableViewY.constant = 15
                tableViewBottom.constant = 46
            }
        }
        stopRefresher()
    }
    
    func stopRefresher() {
        self.refresher.endRefreshing()
    }
    
    func fetchInitialCommentsIfFromPN(){
        let indicator = ActivityIndicator().startAnimating(obj: self)
        let parentId = replyDataFromPN["comment_id"] as? String
        let replyId = replyDataFromPN["reply_id"] as? String

        let url = kcommentDetail + "\(parentId)/?replies[]=[\(replyId)]"
        UCommentHelper.sharedInstance.fetchReplyList(url: url, onCompletion: { (error, data) in
            
            ActivityIndicator().stopAnimating(obj: self, indicator: indicator)
            
            if error == nil{
                
                self.totalCount = data?["count"] as? Int ?? 0
                if let paginatedUrl = data?["next"] as? String{
                    self.paginatedUrl = paginatedUrl
                }else{
                    self.didPaginationEnd = true
                }
                
                if let result = data?["results"] as? [[String:Any]]{
                    
                    self.responseData = result
                    self.tableViewData.removeAll()
                    self.level0Comments.removeAll()
                    self.parentCommentObjectForThreading.isChildHidden = false
                    self.tableViewData.append(self.parentCommentObjectForThreading)
                    
                    for singleReply in self.uCommentInstance.getData(data: self.responseData, paginationUrl:""){
                        singleReply.isChildHidden = true
                        self.tableViewData.append(singleReply)
                    }
                    
                    self.sessionStatus = self.tableViewData.count > 0 ? self.tableViewData[0].sessionStatus : ""
                    
                    for data in self.tableViewData{
                        if data.level == 0{
                            self.level0Comments.append(data)
                        }
                    }
                    self.tableView.emptyDataSetSource = self
                    self.tableView.emptyDataSetDelegate = self
                    self.tableView.reloadData()
                }
            }
        })
        
        
    }
    
    func fetchThreadComments(){
        
        let indicator = ActivityIndicator().startAnimating(obj: self)
        UCommentHelper.sharedInstance.fetchReplyList(url: klistReplies + "\(entityId)" + "/", onCompletion: { (error, data) in//"13926"
            
            ActivityIndicator().stopAnimating(obj: self, indicator: indicator)
            
            if error == nil{
                
                self.totalCount = data?["count"] as? Int ?? 0
                if let paginatedUrl = data?["next"] as? String{
                    self.paginatedUrl = paginatedUrl
                }else{
                    self.didPaginationEnd = true
                }
                
                if let result = data?["results"] as? [[String:Any]]{
                    
                    self.responseData = result
                    self.tableViewData.removeAll()
                    self.level0Comments.removeAll()
                    self.parentCommentObjectForThreading.isChildHidden = false
                    self.tableViewData.append(self.parentCommentObjectForThreading)
                    
                    for singleReply in self.uCommentInstance.getData(data: self.responseData, paginationUrl:""){
                        singleReply.isChildHidden = true
                        self.tableViewData.append(singleReply)
                    }
                    
                    self.sessionStatus = self.tableViewData.count > 0 ? self.tableViewData[0].sessionStatus : ""
                    
                    for data in self.tableViewData{
                        if data.level == 0{
                            self.level0Comments.append(data)
                        }
                    }
                    self.tableView.emptyDataSetSource = self
                    self.tableView.emptyDataSetDelegate = self
                    self.tableView.reloadData()
                }
            }
        })
        
    }
    
    func fetchInitialComments(){
       
        let indicator = ActivityIndicator().startAnimating(obj: self)
        UCommentHelper.sharedInstance.fetchCommentList(self.entityId,isFromProfile: self.isFromPorfile, session: self.session + limit, userId: self.userId , onCompletion: { (error, data) in//"13926"
            
            ActivityIndicator().stopAnimating(obj: self, indicator: indicator)
            
            if error == nil{
                
                self.totalCount = data?["count"] as? Int ?? 0
                if let paginatedUrl = data?["next"] as? String{
                    self.paginatedUrl = paginatedUrl
                }else{
                    self.didPaginationEnd = true
                }
                
                if let result = data?["results"] as? [[String:Any]]{
                    
                    self.responseData = result
                    self.tableViewData.removeAll()
                    self.level0Comments.removeAll()
                    
                    self.tableViewData = self.uCommentInstance.getData(data: self.responseData, paginationUrl:"")
                    //self.sessionStatus = self.tableViewData.count > 0 ? self.tableViewData[0].sessionStatus : ""
                    
                    for data in self.tableViewData{
                        if data.level == 0{
                            self.level0Comments.append(data)
                        }
                    }
                    self.tableView.emptyDataSetSource = self
                    self.tableView.emptyDataSetDelegate = self
                    self.tableView.reloadData()
                }
            }
        })
        
    }
    
    
    func fetchPaginatedComments(){
        
        if didPaginationEnd || level0Comments.count >= totalCount{
            return
        }
        
        UCommentHelper.sharedInstance.fetchPaginatedCommentList(paginatedUrl, onCompletion: { (error, data) in//"13926"
            
            if error == nil{
                
                if let paginatedUrl = data?["next"] as? String{
                    self.paginatedUrl = paginatedUrl
                }else{
                    self.didPaginationEnd = true
                }
                
                if let result = data?["results"] as? [[String:Any]]{
                    
                    self.responseData = result
                    let paginatedData = self.uCommentInstance.getData(data: self.responseData, paginationUrl:"")
                    
                    for data in paginatedData{
                        
                        
                            if data.level == 0{
                                self.level0Comments.append(data)
                            }
                            self.tableViewData.append(data)
                        
                    }
                    
                    self.tableView.reloadData()
                }
            }
        })
    }
    
    func doReport(params:[String:AnyObject]){
        
        let indicator = ActivityIndicator().startAnimating(obj: self)
        UCommentHelper.sharedInstance.request(params, url: kreportComment, onCompletion: { (error, data) in
            
            ActivityIndicator().stopAnimating(obj: self, indicator: indicator)
            
            if error == nil{
                self.makeAlert(title: nil, message: "You have reported this comment successfully.")
            }
            else{
                self.makeAlert(title: nil, message: "Something went wrong please try again.")
            }
        })
    }
    
    func editComment(cell: UCommentCell){
        
        replyIndexPath = tableView.indexPath(for: cell)
        let replyVc = UIViewController()
        let replyView = UCommentPopUp.instanceFromNib()
        replyView.uCommentPopUpDel = self
        replyView.isEdit = true
        replyView.isReplyComment = false
        replyView.commentTextView.text = cell.comments.text

        replyView.sectionHeader.text = ""
        replyView.commentObject = cell.commentObject
        replyView.commentId = cell.commentObject.id
        replyView.frame = replyVc.view.frame
        replyVc.view.addSubview(replyView)
        self.present(replyVc, animated: true, completion: nil)
        
    }
    
    func insertObject(data:[[String:AnyObject]], isComment:Bool, isMultipleReplies:Bool = false,paginationUrl:String){
        
        let commentList = self.uCommentInstance.getData(data: data, paginationUrl:paginationUrl)
            
        if !isMultipleReplies{        // Insert single comment for reply and comment

            if isComment{
                tableViewData.append(commentList[0])
                let indexPath = IndexPath(row: tableViewData.count - 1 , section: 0)
                tableView.insertRows(at: [indexPath], with: .fade)
                tableViewData.rearrange(from: indexPath.row, to: 0)
                tableView.reloadData()
                tableView.scrollToRow(at: IndexPath(row: 0 , section: 0), at: .top, animated: false)
                
            }else{
                
                tableViewData[(replyIndexPath?.row)!].isChildHidden = false
                tableViewData[(replyIndexPath?.row)!].replyCount = tableViewData[(replyIndexPath?.row)!].replyCount + 1
                
                commentList[0].isHidden = false
                tableViewData.append(commentList[0])
                tableViewData.rearrange(from:tableViewData.count - 1 , to: (replyIndexPath?.row)! + 1 )
                let indexPath = IndexPath(row: replyIndexPath!.row + 1 , section: 0)
                tableView.insertRows(at: [indexPath], with: .fade)
                tableView.reloadData()
                tableView.scrollToRow(at: IndexPath(row: replyIndexPath!.row + 1 , section: 0), at: .top, animated: false)
            }
        }
        else{//Insert multiple replies on clicking "X Replies"
            
            var index = (replyIndexPath?.row)! + 1
            for eachComment in commentList{
                
                //eachComment.isHidden = false
                if !tableViewData.contains(eachComment){
                    eachComment.isChildHidden = true
                    tableViewData.append(eachComment)
                    tableViewData.rearrange(from:tableViewData.count - 1 , to: (index))
                    
                    let indexPath = IndexPath(row: index , section: 0)
                    tableView.insertRows(at: [indexPath], with: .bottom)
                    index += 1
                }
                //reload()
            }
        }
    }
    
}
