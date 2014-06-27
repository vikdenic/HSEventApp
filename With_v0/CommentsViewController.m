//
//  CommentsViewController.m
//  With_v0
//
//  Created by Blake Mitchell on 6/17/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import "CommentsViewController.h"
#import "CommentsTableViewCell.h"

@interface CommentsViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *textField;
//@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextField *commentTextFieldOutlet;

@property NSMutableArray *commentsArray;

///
@property NSString *enteredText;

@end

@implementation CommentsViewController


#pragma mark - send button  CGAFFINE!!!!! //------------------------------------------------
- (IBAction)sendButtonPressed:(UIButton *)sender
{
    [self.view endEditing:YES];

    self.enteredText = self.commentTextFieldOutlet.text;

    //Create Comment Object
    PFObject *picComment = [PFObject objectWithClassName:@"CommentActivity"];

    //this adds the text into parse key textContent
    [picComment setObject:self.enteredText forKey:@"commentContent"];

    //This Creates relationship to the user!
    [picComment setObject:[PFUser currentUser].username forKey:@"fromUser"];

    //Save comment
    [picComment saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            [self gettingComments];
            [self.tableView reloadData];

        }
    }];

    self.commentTextFieldOutlet.text = @"";

//    // Create our Installation query
//    PFQuery *pushQuery = [PFInstallation query];
//    [pushQuery whereKey:@"deviceType" equalTo:@"ios"];
//
//    // Send push notification to query
//    [PFPush sendPushMessageToQueryInBackground:pushQuery
//                                   withMessage:@"new chat message in \"event name\""];


    //Animate the send button
    sender.transform = CGAffineTransformMakeScale(.5f, .5f);
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDuration:0.8];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
    CGAffineTransform scaleTrans  = CGAffineTransformMakeScale(1.0f, 1.0f);
    CGAffineTransform lefttorightTrans  = CGAffineTransformMakeTranslation(0.0f,0.0f);
    sender.transform = CGAffineTransformConcat(scaleTrans, lefttorightTrans);
    [UIView commitAnimations];

    [self.commentTextFieldOutlet resignFirstResponder];
}





- (void)viewDidLoad
{
    [super viewDidLoad];

    //Scroll opposite
    [self.tableView setScrollsToTop:YES];

    //Save tableview frame
    CGRect frame = self.tableView.frame;

    //Apply the transform
    self.tableView.transform=CGAffineTransformMakeRotation(M_PI);
    self.tableView.frame = frame;

    //notification for Ugly keyboard animation
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardWillShowNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardWillHideNotification object:nil];

    self.commentsArray = [NSMutableArray array];

    [self gettingComments];

    [self.individualEventPhoto.photo getDataInBackgroundWithBlock:^(NSData *data, NSError *error)
     {
         if (!error)
         {
             UIImage *temporaryImage = [UIImage imageWithData:data];

             //self.imageView.image = temporaryImage;
         }
     }];

    [self.textField becomeFirstResponder];
}

- (void)gettingComments
{

    [self.commentsArray removeAllObjects];

    PFRelation *relation = [self.individualEventPhoto.object relationForKey:@"commentActivity"];
    PFQuery *query = [relation query];
    [query includeKey:@"fromUser"];
    [query includeKey:@"createdAt"];
    [query orderByAscending:@"createdAt"];

query.cachePolicy = kPFCachePolicyCacheThenNetwork;
[query findObjectsInBackgroundWithBlock:^(NSArray *results, NSError *error)
 {
     if (!error)
     {

         [self.commentsArray addObjectsFromArray:results];
     }
     [self.tableView reloadData];
 }];

}

#pragma mark - Table View

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.commentsArray.count;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PFObject *comment = [self.commentsArray objectAtIndex:indexPath.row];


    CommentsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    cell.commentLabel.text = [comment objectForKey:@"commentContent"];

    //setting the time since comment was uploaded
    NSDate *timeOfPicture = [comment valueForKey:@"createdAt"];
    int seconds = -(int)[timeOfPicture timeIntervalSinceNow];
    int minutes = seconds/60;

    if (minutes < 60) {
        cell.timeLabel.text = [NSString stringWithFormat:@"%im", minutes];
    } else if (minutes > 60 && minutes < 1440)
    {
        minutes = minutes/60;
        cell.timeLabel.text = [NSString stringWithFormat:@"%ih", minutes];
    } else {
        minutes = minutes/1440;
        cell.timeLabel.text = [NSString stringWithFormat:@"%id", minutes];
    }

    PFObject *userName = [[comment objectForKey:@"fromUser"] objectForKey:@"username"];
    cell.nameLabel.text = [NSString stringWithFormat:@"%@", userName];


    PFFile *userProfilePhoto = [[comment objectForKey:@"fromUser"] objectForKey:@"userProfilePhoto"];

    [userProfilePhoto getDataInBackgroundWithBlock:^(NSData *data, NSError *error)
     {
         if (!error)
         {
             //this will already be set to the right image size- can we round it too?
             UIImage *image = [UIImage imageWithData:data];
             cell.theImageView.image = image;
             cell.theImageView.layer.cornerRadius = cell.theImageView.bounds.size.width/2;
             cell.theImageView.layer.borderColor = [[UIColor colorWithRed:202/255.0 green:250/255.0 blue:53/255.0 alpha:1] CGColor];
             cell.theImageView.layer.borderWidth = 2.0;
             cell.theImageView.layer.masksToBounds = YES;
             cell.theImageView.backgroundColor = [UIColor redColor];

         } else {
             cell.theImageView.image = [UIImage imageNamed:@"clock"];
         }
    }];
    return cell;
}

#pragma mark - Text Field

//input accesorry view- view attached to the top of the keyboard


//-(BOOL)textFieldShouldReturn:(UITextField *)textField
//{
////    PFObject *object = self.commentObject;
//    PFUser *picturePhotographer = [self.individualEventPhoto.object objectForKey:@"photographer"];
//
//    PFObject *comment = [PFObject objectWithClassName:@"CommentActivity"];
//    comment[@"fromUser"] = [PFUser currentUser];
//    comment[@"toUser"] = picturePhotographer;
//    comment[@"photo"] = self.individualEventPhoto.object;
//    comment[@"commentContent"] = self.textField.text;
//    [comment saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
//     {
//         PFRelation *relation = [self.individualEventPhoto.object relationForKey:@"commentActivity"];
//         [relation addObject:comment];
//         [self.individualEventPhoto.object saveInBackground];
//    }];
//
//    [self.commentTextFieldOutlet resignFirstResponder];
//
//    return YES;
//}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.commentTextFieldOutlet resignFirstResponder];
}







#pragma mark - Keyboard animation stuff //------------------------------------------------

//new style keyboard animation
- (void) keyboardDidShow:(NSNotification *)notification
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] intValue]];
    [UIView setAnimationDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] intValue]];


    if ([[UIScreen mainScreen] bounds].size.height == 1136)
    {
        [self.view setFrame:CGRectMake(0, -220, 640, 1120)];
    } else {
        [self.view setFrame:CGRectMake(0, -220, 640, 920)];
    }

    [UIView commitAnimations];
}


//Old style
- (void) keyboardDidHide:(NSNotification *)notification
{
    if ([[UIScreen mainScreen] bounds].size.height == 1136)
    {
        [UIView animateWithDuration:0.25 animations:^{
            [self.view setFrame:CGRectMake(0, 0, 640, 1120)];
        }];
    } else {
        [UIView animateWithDuration:0.25 animations:^{
            [self.view setFrame:CGRectMake(0, 0, 640, 920)];
        }];
    }
}














//- (void)getComments
//{
//    PFQuery *query = [PFQuery queryWithClassName:@"CommentActivity"];
//    [query whereKey:@"photo" equalTo:self.commentObject];
//    [query includeKey:@"fromUser"];
//    [query orderByAscending:@"createdAt"];
//
//    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
//     {
//         [self.commentsArray addObjectsFromArray:objects];
//         [self.tableView reloadData];
//    }];
//}

@end
