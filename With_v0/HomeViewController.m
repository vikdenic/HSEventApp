//
//  HomeViewController.m
//  With_v0
//
//  Created by Vik Denic on 6/15/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import "HomeViewController.h"
#import <Parse/Parse.h>
#import "HomeTableViewCell.h"
#import "IndividualEventViewController.h"
#import "PageViewController.h"
#import "LoginViewController.h"

@interface HomeViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property UIRefreshControl *refreshControl;

@property NSMutableArray *eventArray;
@property NSMutableArray *indexPathArray;

@end

@implementation HomeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.eventArray = [NSMutableArray array];
    self.indexPathArray = [NSMutableArray array];

    self.tabBarController.tabBar.tintColor = [UIColor orangeColor];

    PFUser *currentUser = [PFUser currentUser];

        if (currentUser)
        {

        } else {
            
            [self performSegueWithIdentifier:@"showLogin" sender:self];
        }

    //pull to refresh
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    [self.tableView addSubview:refreshControl];

    [[self navigationController] setNavigationBarHidden:NO animated:YES];

    [self queryForEvents];
}

#pragma mark - Table View

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.eventArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HomeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];

    if (cell == nil) {
        cell = [[HomeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }

    PFObject *object = [self.eventArray objectAtIndex:indexPath.row];

    dispatch_queue_t queue2 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);

    PFFile *userProfilePhoto = [[object objectForKey:@"creator"] objectForKey:@"userProfilePhoto"];
    [userProfilePhoto getDataInBackgroundWithBlock:^(NSData *data, NSError *error)
     {
         dispatch_async(queue2, ^{
             UIImage *temporaryImage = [UIImage imageWithData:data];

         cell.creatorImageView.layer.cornerRadius = cell.creatorImageView.bounds.size.width/2;
         cell.creatorImageView.layer.borderColor = [[UIColor colorWithRed:202/255.0 green:250/255.0 blue:53/255.0 alpha:1] CGColor];
         cell.creatorImageView.layer.borderWidth = 2.0;
         cell.creatorImageView.layer.masksToBounds = YES;
//         cell.creatorImageView.backgroundColor = [UIColor redColor];

         dispatch_sync(dispatch_get_main_queue(), ^{
             cell.creatorImageView.image = temporaryImage;
            });
        });
     }];

    //this gets the image not on the main thread
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul);
    PFFile *file = [object objectForKey:@"themeImage"];
    [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error)
     {
         dispatch_async(queue, ^{
             UIImage *image = [UIImage imageWithData:data];

             dispatch_sync(dispatch_get_main_queue(), ^{
                cell.themeImageView.image = image;
             });
         });
     }];

    //creator username
    PFObject *userName = [[object objectForKey:@"creator"] objectForKey:@"username"];
    cell.creatorNameLabel.text = [NSString stringWithFormat:@"%@", userName];

    //event Name and Date;
    cell.eventNameLabel.text = object[@"title"];
    cell.eventDateLabel.text = object[@"eventDate"];

    cell.accessoryType = UITableViewCellAccessoryNone;

    NSInteger sectionsAmount = [tableView numberOfSections];
    NSInteger rowsAmount = [tableView numberOfRowsInSection:[indexPath section]];
    if ([indexPath section] == sectionsAmount - 1 && [indexPath row] == rowsAmount - 1)
    {
        //do this before the user gets to the bottom, so like 4 before the bottom
        [self queryForEvents];

        ///so what if it's the bottom and there is no more, how to stop it from continually doing this- only do it once
    }

    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Query for Events

- (void)queryForEvents
{
    PFQuery *query = [PFQuery queryWithClassName:@"Event"];
    [query includeKey:@"creator"];
    query.limit = 4;

    if (self.eventArray.count == 0)
    {
        query.skip = 0;

    } else
    {
        query.skip = self.eventArray.count;
    }
    query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (self.eventArray.count < 3)
         {
            [self.eventArray addObjectsFromArray:objects];
            [self.tableView reloadData];

         } else if (self.eventArray.count >= 3)
         {
             int theCount = (int)self.eventArray.count;
             [self.eventArray addObjectsFromArray:objects];

             for (int i = theCount; i <= self.eventArray.count-1; i++)
             {
                 NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
                 [self.indexPathArray addObject:indexPath];
             }

             [self.tableView insertRowsAtIndexPaths:self.indexPathArray withRowAnimation:UITableViewRowAnimationFade];
             [self.indexPathArray removeAllObjects];
         }
    }];
}

#pragma mark - Pull To Refresh

- (void)refresh:(UIRefreshControl *)refreshControl
{
    [self queryForEvents];
    [self performSelector:@selector(stopRefresh) withObject:nil afterDelay:2.0];
}

- (void)stopRefresh
{
    [self.refreshControl endRefreshing];
}

#pragma mark - Segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ToPageViewControllerSegue"])
    {
        NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
        self.event = [self.eventArray objectAtIndex:selectedIndexPath.row];
        PageViewController *pageViewController = segue.destinationViewController;
        pageViewController.event = self.event;

    }
    else if([segue.identifier isEqualToString:@"showLogin"])
    {
        {
            LoginViewController *loginVC = segue.destinationViewController;
            loginVC.hidesBottomBarWhenPushed = YES;
        }
    }
}

- (IBAction)unwindSegueToHomeViewController:(UIStoryboardSegue *)sender
{

}

@end















//    PFUser *currentUser = [PFUser currentUser];
//
//    //there is a bug here where the user can go to the home screen here//disable and hide the tab bar;
//
//    if (currentUser)
//    {
//
//    } else{
//        [self performSegueWithIdentifier:@"showLogin" sender:self];
//    }
//
//    //pull to refresh
//    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
//    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
//    self.refreshControl = refreshControl;
//
//    [self.tableView addSubview:refreshControl];
//
//    [[self navigationController] setNavigationBarHidden:YES animated:YES];
//
//    [self queryForEvents];



