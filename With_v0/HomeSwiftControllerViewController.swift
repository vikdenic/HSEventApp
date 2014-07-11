//
//  HomeSwiftControllerViewController.swift
//  With_v0
//
//  Created by Vik Denic on 7/9/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

//-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
//{
//    if ([segue.identifier isEqualToString:@"ToPageViewControllerSegue"])
//    {
//        NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
//        self.event = [self.eventArray objectAtIndex:selectedIndexPath.row];
//        PageViewController *pageViewController = segue.destinationViewController;
//        pageViewController.event = self.event;
//
//    }
//    else if([segue.identifier isEqualToString:@"showLogin"])
//    {
//        {
//            LoginViewController *loginVC = segue.destinationViewController;
//            loginVC.hidesBottomBarWhenPushed = YES;
//        }
//    }
//}
//
//@property (weak, nonatomic) IBOutlet UITableView *tableView;
//@property UIRefreshControl *refreshControl;
//
//@property NSMutableArray *eventArray;
//@property NSMutableArray *indexPathArray;
//
//@property BOOL doingTheQuery;
//
//@property (nonatomic) CGRect originalFrame;

//@property PFObject *event;

import UIKit

extension Array{
    func appendNSArray(anNSArray:NSArray) -> Array{
        return anNSArray as Array
    }
}

class HomeSwiftControllerViewController: UIViewController, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate {
//    var tableView : UITableView?

    @IBOutlet var tableView: UITableView
    var refreshControl: UIRefreshControl = UIRefreshControl()
    var eventArray = [PFObject]()
    var indexPathArray = [NSIndexPath]()
    var startContentOffset = CGFloat()
    var lastContentOffset = CGFloat()
    var hidden = Bool()
//    var eventArray = [AnyObject]()

    var doingTheQuery : Bool = false
//    init(){
//        doingTheQuery = false
////        super.init(nibName: nil, bundle: nil)
//        super.init(nibName: nil, bundle: nil)
//    }
    var originalFrame : CGRect = CGRectMake(0, 0, 0, 0)
    var event : PFObject?

    let limeGreen : UIColor = UIColor(red: 202/255.0, green: 250/255.0, blue: 53/255.0, alpha: 1)

    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!)
    {
        if segue.identifier == "ToPageViewControllerSegue"
        {
            var selectedIndexPath : NSIndexPath = tableView!.indexPathForSelectedRow()
            event = eventArray[selectedIndexPath.row]
            var pageViewController : PageViewController = segue.destinationViewController as PageViewController //downcasting
            pageViewController.event = event
        }
        else if segue.identifier == "showLogin"
        {
            var loginVC : LoginViewController = segue.destinationViewController as LoginViewController
            loginVC.hidesBottomBarWhenPushed = true
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        originalFrame = self.tabBarController.tabBar.frame

        tabBarController.tabBar.tintColor = limeGreen

        var currentUser : PFUser? = PFUser.currentUser()

        if currentUser
        {
            queryForEvents()
        }
        else
        {
            performSegueWithIdentifier("showLogin", sender: self)
        }

        var refreshControl2 = UIRefreshControl()
        refreshControl2.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)

        refreshControl = refreshControl2
        tableView.addSubview(refreshControl)

        navigationController.setNavigationBarHidden(false, animated: true)

        var newBackButton = UIBarButtonItem(title: "Home", style: UIBarButtonItemStyle.Bordered, target: nil, action: nil)

        navigationItem.backBarButtonItem = newBackButton
    }

    //NSNotificationCenter
    func receiveNotification(notification : NSNotification) -> Void
    {
        if notification.name == "Test1"
        {
            eventArray.removeAll(keepCapacity: false)
            tableView.reloadData()
        }
    }

    //PULL TO REFRESH
    func refresh(refreshControl : UIRefreshControl) -> Void
    {
        queryForEvents()
        var timer = NSTimer.scheduledTimerWithTimeInterval(1.5, target: self, selector: "stopRefresh", userInfo: nil, repeats: false)
    }

    func stopRefresh() -> Void
    {
        refreshControl.endRefreshing()
    }

    func queryForEvents()->Void
    {
        var relation: PFRelation = PFUser.currentUser().relationForKey("eventsAttending")
        let query: PFQuery = relation.query()
        query.includeKey("creator")
        query.limit = 4

        if eventArray.count == 0
        {
            query.skip = 0
        }
        else
        {
            query.skip = eventArray.count
        }

        query.findObjectsInBackgroundWithBlock({objects,error in
            self.doingTheQuery = true


            if self.eventArray.count < 3
            {
                //*NSLOG THIS TO MAKE SURE IT WORKS
                self.eventArray.appendNSArray(objects)

                self.tableView.reloadData()
            }
            else if self.eventArray.count >= 3
            {
                var theCount: Int = self.eventArray.count
                //*NSLOG THIS TO MAKE SURE IT WORKS
                self.eventArray.appendNSArray(objects)

                for var i : Int = theCount; i <= self.eventArray.count-1; i++
                {
                    var indexPath = NSIndexPath(forItem: i, inSection: 0)
                    self.indexPathArray += indexPath
                }

                self.tableView.insertRowsAtIndexPaths(self.indexPathArray, withRowAnimation:UITableViewRowAnimation.Fade)
                self.indexPathArray.removeAll(keepCapacity: false)

                self.tableView.reloadData()
            }
            self.doingTheQuery = false
        })
    }

    override func viewWillAppear(animated: Bool)
    {
        tabBarController.tabBar.hidden = false
    }

    //TableView
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int
    {

        return(self.eventArray.count)
    }

    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell!
    {
        let cell : HomeTableViewCell = tableView.dequeueReusableCellWithIdentifier("Cell") as HomeTableViewCell

//IGNORING THIS B/C DOWNCASTING ENSURES CELL IS NOT NIL
//        if (cell == nil) {
//            cell = [[HomeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
//        }

        var object : PFObject = eventArray[indexPath.row]

        var queue2 : dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0) //0ul?

        var userProfilePhoto : PFFile = object.objectForKey("creator").objectForKey("userProfilePhoto") as PFFile


        userProfilePhoto.getDataInBackgroundWithBlock({data, error in
            if data == nil
            {
                cell.creatorImageView.image = nil
            }
            else
            {

//**                dispatch_async(queue2, ^{
//                    UIImage *temporaryImage = [UIImage imageWithData:data];
                dispatch_async(queue2, ({
                    var temporaryImage : UIImage = UIImage(data: data)

                    cell.creatorImageView.layer.cornerRadius = cell.creatorImageView.bounds.size.width/2
                    cell.creatorImageView.layer.borderColor = self.limeGreen.CGColor
                    cell.creatorImageView.layer.borderWidth = 2.0
                    cell.creatorImageView.layer.masksToBounds = true


//**                dispatch_sync(dispatch_get_main_queue(), ^{
//                    cell.creatorImageView.image = temporaryImage;
//                    });
                dispatch_sync(dispatch_get_main_queue(), ({
                    cell.creatorImageView.image = temporaryImage
                    }))
                }))
                var queue : dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0) //0ul?

                var file : PFFile = object.objectForKey("themeImage") as PFFile

                file.getDataInBackgroundWithBlock({data, error in

//**                    dispatch_async(queue, ^{
//                        UIImage *image = [UIImage imageWithData:data];
//
//                        dispatch_sync(dispatch_get_main_queue(), ^{
//                            cell.themeImageView.image = image;
//                            });
//                        });
                    dispatch_async(queue2, ({

                        var image = UIImage(data: data)

                        dispatch_sync(dispatch_get_main_queue(), ({
                            cell.themeImageView.image = image
                        }))

                        }))
                })
            }
        })

        var userName : PFObject = object.objectForKey("creator").objectForKey("username") as PFObject

        cell.creatorNameLabel.text = "\(userName)"
        cell.eventNameLabel.text = object.objectForKey("title") as String
        cell.eventDateLabel.text = object.objectForKey("eventDate") as String
        cell.accessoryType = UITableViewCellAccessoryType.None

        var sectionsAmount : NSInteger = tableView.numberOfSections()
        var rowsAmount : NSInteger = tableView.numberOfRowsInSection(indexPath.section)

        if indexPath.section == sectionsAmount - 1 && indexPath.row == rowsAmount - 1
        {
            if !self.doingTheQuery
            {
                queryForEvents()
            }
        }

        return cell
    }

    func tableView(tableView: UITableView!, didDeselectRowAtIndexPath indexPath: NSIndexPath!)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }


    //ScrollStuff
    //the magic!
    func expand()
    {
        if hidden
        {
        return
        }

        hidden = true

        tabBarController .setTabBarHidden(true, animated: true)
        navigationController .setNavigationBarHidden(false, animated: true)
    }

    func contract()
    {
        if !hidden
        {
            return
        }

        hidden = false

        tabBarController.setTabBarHidden(false, animated: true)
        navigationController .setNavigationBarHidden(false, animated: true)
    }

    //ScrollViewDelegate
    func scrollViewWillBeginDragging(scrollView: UIScrollView!)
    {
        startContentOffset = lastContentOffset

        lastContentOffset = scrollView.contentOffset.y
    }

    func scrollViewDidScroll(scrollView: UIScrollView!)
    {
        var currentOffset : CGFloat = scrollView.contentOffset.y
        var differenceFromStart : CGFloat = startContentOffset - currentOffset
        var differenceFromLast : CGFloat = lastContentOffset - currentOffset
        lastContentOffset = currentOffset

        if differenceFromStart < 0
        {
            if scrollView.tracking && abs(differenceFromLast)>1
            {
                expand()
            }
        }
        else
        {
            if scrollView.tracking && abs(differenceFromLast)>1
            {
                contract()
            }
        }
    }

    func scrollViewDidEndDragging(scrollView: UIScrollView!, willDecelerate decelerate: Bool)
    {
    }

    func scrollViewDidEndDecelerating(scrollView: UIScrollView!)
    {
    }

    func scrollViewShouldScrollToTop(scrollView: UIScrollView!) -> Bool
    {
        contract()
        return true
    }

    //IBACTIONS

    @IBAction func showActionSheet(sender: AnyObject)
    {

        var actionSheet : UIActionSheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil)

        actionSheet.showInView(view)
    }

    func actionSheet(actionSheet: UIActionSheet!, clickedButtonAtIndex buttonIndex: Int)
    {
        var theButtonIndex : String = actionSheet.buttonTitleAtIndex(buttonIndex)

        if theButtonIndex == "Cancel"
        {

        }
        else if theButtonIndex == "Report"
        {

        }

    }

    @IBAction func unwindSegueToHomeViewController(sender: UIStoryboardSegue)
    {

    }

    @IBAction func unwindSegueInvitesToHome(sender: UIStoryboardSegue)
    {

    }

}




