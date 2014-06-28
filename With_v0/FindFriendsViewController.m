//
//  FindFriendsViewController.m
//  With_v0
//
//  Created by Vik Denic on 6/15/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import "FindFriendsViewController.h"
#import <Parse/Parse.h>
#import "FindFriendsTableViewCell.h"
#import "FriendsListFriendButton.h"

@interface FindFriendsViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property NSMutableArray *results;

@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) NSString *userSearch;
@property BOOL resultsToDisplay;

@end

@implementation FindFriendsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.results = [NSMutableArray array];

    UIBarButtonItem *newBackButton =
    [[UIBarButtonItem alloc] initWithTitle:@"Find Friends"
                                     style:UIBarButtonItemStyleBordered
                                    target:nil
                                    action:nil];
    [[self navigationItem] setBackBarButtonItem:newBackButton];

    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    [self.tableView addGestureRecognizer:gestureRecognizer];

    self.resultsToDisplay = YES;
    self.tableView.separatorColor = [UIColor whiteColor];
    [self.textField becomeFirstResponder];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.textField.text = nil;
}

- (IBAction)onSearchButtonTapped:(id)sender
{
    self.tableView.backgroundColor = [UIColor whiteColor];

    [self searchForFriends];
    [self.textField resignFirstResponder];
}

#pragma mark - TableView

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.resultsToDisplay == YES)
    {
        return self.results.count;
    } else {
        return 1;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FindFriendsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];

    if (self.resultsToDisplay == NO)
    {
        cell.usernameLabel.text = @"No Results";
        self.tableView.separatorColor = [UIColor whiteColor];
        return cell;
    }

    self.tableView.separatorColor = [UIColor grayColor];

    PFUser *user = [self.results objectAtIndex:indexPath.row];
    cell.friendButton.otherUser = user;

    cell.usernameLabel.text = [NSString stringWithFormat:@"%@", user.username];

    PFFile *userProfilePhoto = [user objectForKey:@"userProfilePhoto"];
    [userProfilePhoto getDataInBackgroundWithBlock:^(NSData *data, NSError *error)
     {
         UIImage *temporaryImage = [UIImage imageWithData:data];
         cell.profilePictureImageView.image = temporaryImage;

         ///if nil, set it to something we create
     }];

    cell.friendButton.tag = indexPath.row;
    [cell.friendButton addTarget:self action:@selector(ontapped:) forControlEvents:UIControlEventTouchUpInside];

    PFQuery *toUserQuery = [PFQuery queryWithClassName:@"Friendship"];
    [toUserQuery whereKey:@"toUser" equalTo:[PFUser currentUser]];
    [toUserQuery whereKey:@"fromUser" equalTo:user];

    PFQuery *fromUserQuery = [PFQuery queryWithClassName:@"Friendship"];
    [fromUserQuery whereKey:@"fromUser" equalTo:[PFUser currentUser]];
    [fromUserQuery whereKey:@"toUser" equalTo:user];

    PFQuery *combinedQuery = [PFQuery orQueryWithSubqueries:@[toUserQuery,fromUserQuery]];
    [combinedQuery includeKey:@"fromUser"];
    [combinedQuery includeKey:@"toUser"];

    [combinedQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error)
    {

         cell.friendButton.friendshipObject = object;

         if ([[object objectForKey:@"status"] isEqualToString:@"Approved"])
         {
             UIImage *btnImage = [UIImage imageNamed:@"added_button_image"];
             [cell.friendButton setImage:btnImage forState:UIControlStateNormal];

         } else if ([[object objectForKey:@"status"] isEqualToString:@"Pending"])
         {
             UIImage *btnImage = [UIImage imageNamed:@"pending_image"];
             [cell.friendButton setImage:btnImage forState:UIControlStateNormal];

         } else if ([[object objectForKey:@"status"] isEqualToString:@"Denied"])
         {
             UIImage *btnImage = [UIImage imageNamed:@"add_friend_button_image"];
             [cell.friendButton setImage:btnImage forState:UIControlStateNormal];
         } else {
             
             UIImage *btnImage = [UIImage imageNamed:@"add_friend_button_image"];
             [cell.friendButton setImage:btnImage forState:UIControlStateNormal];
         }

         if ([cell.usernameLabel.text isEqualToString:[PFUser currentUser].username])
         {
             [cell.friendButton setImage:nil forState:UIControlStateNormal];
             cell.friendButton.userInteractionEnabled = NO;
         }

     }];

    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)ontapped:(FindFriendsFriendButton *)sender
{
    PFUser *user = [self.results objectAtIndex:sender.tag];

    if ([sender.imageView.image isEqual:[UIImage imageNamed:@"add_friend_button_image"]])
    {
        UIImage *btnImage = [UIImage imageNamed:@"pending_image"];
        [sender setImage:btnImage forState:UIControlStateNormal];

        if (sender.friendshipObject == nil)
        {
            PFObject *friendship = [PFObject objectWithClassName:@"Friendship"];
            friendship[@"fromUser"] = [PFUser currentUser];
            friendship[@"toUser"] = user;
            friendship[@"status"] = @"Pending";
            [friendship saveInBackground];

        } else {
            sender.friendshipObject[@"status"] = @"Pending";
            [sender.friendshipObject saveInBackground];
        }

    } else if ([sender.imageView.image isEqual:[UIImage imageNamed:@"added_button_image"]])
    {
        UIImage *btnImage = [UIImage imageNamed:@"add_friend_button_image"];
        [sender setImage:btnImage forState:UIControlStateNormal];
        {
            [sender.friendshipObject deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
             {
                 PFObject *friendship = [PFObject objectWithClassName:@"Friendship"];
                 friendship[@"fromUser"] = [PFUser currentUser];
                 friendship[@"toUser"] = sender.otherUser;
                 friendship[@"status"] = @"Denied";
                 [friendship saveInBackground];
             }];
        }

    } else if ([sender.imageView.image isEqual:[UIImage imageNamed:@"pending_image"]])
    {
        UIImage *btnImage = [UIImage imageNamed:@"add_friend_button_image"];
        [sender setImage:btnImage forState:UIControlStateNormal];

        sender.friendshipObject[@"status"] = @"Denied";
        [sender.friendshipObject saveInBackground];
        
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];

    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.separatorColor = [UIColor whiteColor];

    return YES;
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    self.textField.text = nil;

    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.separatorColor = [UIColor whiteColor];

    return YES;
}

- (void)searchForFriends
{
    //Say no users found if nothing comes back? so if count is zero or nil

    [self.results removeAllObjects];

    PFQuery *query = [PFQuery queryWithClassName:@"_User"];
//    NSString *searchString = [self.textField.text lowercaseString];
    [query whereKey:@"username" containsString:self.textField.text];
    ///trim white space?
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (objects.count >= 1)
         {
             [self.results addObjectsFromArray:objects];
             [self.tableView reloadData];
             self.resultsToDisplay = YES;
         } else {
             self.resultsToDisplay = NO;
             [self.tableView reloadData];
             self.textField.text = nil;
         }
    }];
}

#pragma mark - Tap Gesture

- (void) hideKeyboard {
    [self.textField resignFirstResponder];
    self.tableView.backgroundColor = [UIColor whiteColor];
}

@end
