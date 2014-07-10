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

class HomeSwiftControllerViewController: UIViewController {
//    var tableView : UITableView?

    @IBOutlet var tableView: UITableView
    var refreshControl: UIRefreshControl?
    var eventArray = [PFObject]()
    var indexPathArray = [NSIndexPath]()
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

        var testUser :PFUser? = PFUser.currentUser()

        if testUser
        {
            println(testUser)
        }
        else{
            println("It was nil yo")
        }
    }
//    - (void)refresh:(UIRefreshControl *)refreshControl
//    {
//    [self queryForEvents];
//    [self performSelector:@selector(stopRefresh) withObject:nil afterDelay:2.0];
//    }
//
//    - (void)stopRefresh
//    {
//    [self.refreshControl endRefreshing];
//    }

//*    func refresh(refreshControl: UIRefreshControl) {
//        queryForEvents
//        
//    }
//
//    - (void)queryForEvents
//    {
//
//    PFRelation *relation = [[PFUser currentUser] relationForKey:@"eventsAttending"];
//    PFQuery *query = [relation query];
//    [query includeKey:@"creator"];
//    query.limit = 4;
//
//    if (self.eventArray.count == 0)
//    {
//    query.skip = 0;
//
//    } else
//    {
//    query.skip = self.eventArray.count;
//    }
//    //  query.cachePolicy = kPFCachePolicyCacheThenNetwork;
//    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
//    {
//    self.doingTheQuery = YES;
//
//    if (self.eventArray.count < 3)
//    {
//    [self.eventArray addObjectsFromArray:objects];
//    [self.tableView reloadData];
//
//    } else if (self.eventArray.count >= 3)
//    {
//    int theCount = (int)self.eventArray.count;
//    [self.eventArray addObjectsFromArray:objects];
//
//    for (int i = theCount; i <= self.eventArray.count-1; i++)
//    {
//    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
//    [self.indexPathArray addObject:indexPath];
//    }
//
//    [self.tableView insertRowsAtIndexPaths:self.indexPathArray withRowAnimation:UITableViewRowAnimationFade];
//    [self.indexPathArray removeAllObjects];
//    ///
//    [self.tableView reloadData];
//    }
//    self.doingTheQuery = NO;
//    }];
//    }


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
            }

        })

    }

}