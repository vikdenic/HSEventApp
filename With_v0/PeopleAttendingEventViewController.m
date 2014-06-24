//
//  PeopleAttendingEventViewController.m
//  With_v0
//
//  Created by Blake Mitchell on 6/24/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import "PeopleAttendingEventViewController.h"
#import "PeopleAttendingTableViewCell.h"

@interface PeopleAttendingEventViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property NSMutableArray *usersAttendingArray;

@end

@implementation PeopleAttendingEventViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.usersAttendingArray = [NSMutableArray array];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self usersAttendingQuery];

}

- (void)usersAttendingQuery
{
    PFRelation *relation = [self.event relationForKey:@"usersAttending"];
    PFQuery *query = [relation query];

    [query findObjectsInBackgroundWithBlock:^(NSArray *results, NSError *error)
     {
         self.usersAttendingArray = [NSMutableArray arrayWithArray:results];
         [self.tableView reloadData];
     }];
}

#pragma mark - Table View 

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.usersAttendingArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PeopleAttendingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];

    PFUser *user = [self.usersAttendingArray objectAtIndex:indexPath.row];

    cell.usernameLabel.text = [NSString stringWithFormat:@"%@", user[@"username"]];


    PFFile *userProfilePhoto = [user objectForKey:@"userProfilePhoto"];
    [userProfilePhoto getDataInBackgroundWithBlock:^(NSData *data, NSError *error)
     {
             UIImage *temporaryImage = [UIImage imageWithData:data];
             cell.profilePictureImageView.image = temporaryImage;
     }];

    //set it in storyboard and do the for thing like max showed me earlier so set it to no and then if they are friend switch it
    UIButton *button = [[UIButton alloc]init];
    [button setImage:[UIImage imageNamed:@"like_selected"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(ontapped:) forControlEvents:UIControlEventTouchUpInside];
    button.tag = indexPath.row;
    cell.accessoryView = button;

    return cell;
}

- (void)ontapped:(UIButton *)sender
{
    [sender setImage:[UIImage imageNamed:@"like_unselected"] forState:UIControlStateNormal];

    ///here we need to actually create the relation between the users

    //             PFRelation *relation = [individualEventPhoto.object relationforKey:@"likeActivity"];
    //             [relation addObject:like];
    //             [individualEventPhoto.object saveInBackground];


}


@end
