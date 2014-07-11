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

class HomeSwiftControllerViewController: UIViewController, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource {
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

        let limeGreen : UIColor = UIColor(red: 202/255.0, green: 250/255.0, blue: 53/255.0, alpha: 1)

        tabBarController.tabBar.tintColor = UIColor.greenColor()

        var currentUser : PFUser? = PFUser.currentUser()

        if currentUser
        {
            queryForEvents()
        }
        else
        {
            performSegueWithIdentifier("showLogin", sender: self)
        }
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

    //TableView
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int
    {
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
    }


}




