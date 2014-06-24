//
//  StreamEventViewController.m
//  With_v0
//
//  Created by Blake Mitchell on 6/16/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import "StreamEventViewController.h"
#import "StreamTableViewCell.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <Parse/Parse.h>
#import "CommentsViewController.h"
#import "IndividualEventPhoto.h"

@interface StreamEventViewController () <UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property UIImagePickerController *cameraController;

@property (strong, nonatomic) NSURL *videoUrl;
@property (strong, nonatomic) MPMoviePlayerController *videoController;

@property UIRefreshControl *refreshControl;


@property NSMutableArray *theLegitArrayOfEverything;

@end

@implementation StreamEventViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    //add a uiimageview and then on viewDidAppear I remove it or animate it out after 1.2 seconds
    self.theLegitArrayOfEverything = [NSMutableArray array];

    //pull to refresh
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    [self.tableView addSubview:refreshControl];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self queryForImages];
}

#pragma mark - Getting Pictures and Videos

- (void)queryForImages
{
    [self.theLegitArrayOfEverything removeAllObjects];

    PFRelation *relation = [self.event relationForKey:@"eventPhotos"];
    PFQuery *query = [relation query];
    [query includeKey:@"photographer"];
    [query includeKey:@"createdAt"];
    [query orderByDescending:@"createdAt"];

    query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    [query findObjectsInBackgroundWithBlock:^(NSArray *results, NSError *error)
     {
        if (!error)
        {
            for (PFObject *object in results)
            {
                PFRelation *relation2 = [object relationForKey:@"likeActivity"];
                PFQuery *query2 = [relation2 query];
                [query includeKey:@"fromUser"];

                [query2 findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
                 {
                     IndividualEventPhoto *individualEventPhoto = [[IndividualEventPhoto alloc]init];

                     individualEventPhoto.likes = [objects mutableCopy];

                     PFFile *file = [object objectForKey:@"photo"];
                     individualEventPhoto.photo = file;
                     individualEventPhoto.object = object;
                     individualEventPhoto.photographerPhoto = [[object objectForKey:@"photographer"] objectForKey:@"userProfilePhoto"];
                     individualEventPhoto.username = [[object objectForKey:@"photographer"] objectForKey:@"username"];

                     [self.theLegitArrayOfEverything addObject:individualEventPhoto];
                 }];
            }
        }
         [self.tableView reloadData];
    }];
}

#pragma mark - Action Methods

//- (IBAction)onLikeButtonTapped:(UIButton *)sender
//{
//    if ([sender.currentBackgroundImage isEqual:[UIImage imageNamed:@"like_unselected"]])
//    {
//
//        NSLog(@"No");
//        
//        UIImage *btnImage = [UIImage imageNamed:@"like_selected"];
//        [sender setImage:btnImage forState:UIControlStateNormal];
//
//        IndividualEventPhoto *individualEventPhoto = [self.theLegitArrayOfEverything objectAtIndex:sender.tag];
//        PFUser *picturePhotographer = [individualEventPhoto.object objectForKey:@"photographer"];
//
//        PFObject *like = [PFObject objectWithClassName:@"LikeActivity"];
//        like[@"fromUser"] = [PFUser currentUser];
//        like[@"toUser"] = picturePhotographer;
//        like[@"photo"] = individualEventPhoto.object;
//        [like saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
//         {
//             PFRelation *relation = [individualEventPhoto.object relationforKey:@"likeActivity"];
//             [relation addObject:like];
//             [individualEventPhoto.object saveInBackground];
//         }];
//
//    }
//    else if ([sender.currentBackgroundImage isEqual:[UIImage imageNamed:@"like_selected"]])
//    {
//
//        NSLog(@"Yep");
//        UIImage *btnImage = [UIImage imageNamed:@"like_unselected"];
//        [sender setImage:btnImage forState:UIControlStateNormal];
//        ///need to remove relation
//    }
//}

- (IBAction)onCommentButtonTapped:(UIButton *)sender
{
    IndividualEventPhoto *individualEventPhoto = [self.theLegitArrayOfEverything objectAtIndex:sender.tag];
    self.individualEventPhoto = individualEventPhoto;
}

#pragma mark - Table View

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGRect frame = tableView.frame;

    IndividualEventPhoto *individualEventPhoto = [self.theLegitArrayOfEverything objectAtIndex:section];

    //setting time top right
    NSDate *timeOfPicture = [individualEventPhoto.object valueForKey:@"createdAt"];
    int seconds = -(int)[timeOfPicture timeIntervalSinceNow];
    int minutes = seconds/60;

    UILabel *timeInterval = [[UILabel alloc] initWithFrame:CGRectMake(230, 5, 100, 30)];
    timeInterval.textColor = [UIColor whiteColor];

        if (minutes < 60) {
            timeInterval.text = [NSString stringWithFormat:@"%im", minutes];
        } else if (minutes > 60 && minutes < 1440)
        {
            minutes = minutes/60;
            timeInterval.text = [NSString stringWithFormat:@"%ih", minutes];
        } else {
            minutes = minutes/1440;
            timeInterval.text = [NSString stringWithFormat:@"%id", minutes];
        }

    //setting the username
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(50, 5, 100, 30)];
    title.text = [NSString stringWithFormat:@"%@", individualEventPhoto.username];
    title.textColor = [UIColor whiteColor];

    UIImageView *customImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 5, 30, 30)];
    customImageView.layer.cornerRadius = customImageView.bounds.size.width/2;
    customImageView.layer.borderColor = [[UIColor colorWithRed:202/255.0 green:250/255.0 blue:53/255.0 alpha:1] CGColor];
    customImageView.layer.borderWidth = 2.0;
    customImageView.layer.masksToBounds = YES;
    [individualEventPhoto.photographerPhoto getDataInBackgroundWithBlock:^(NSData *data, NSError *error)
     {
         if (!error)
         {
             UIImage *image = [UIImage imageWithData:data];
             customImageView.image = image;
         } else {
             customImageView.backgroundColor = [UIColor purpleColor];
         }
     }];

    //TRY TO SET THIS HEADERVIEW TO "STREAM_BLUR_IMAGE"
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    headerView.alpha = .7;
    [headerView addSubview:title];
    [headerView addSubview:timeInterval];
    [headerView addSubview:customImageView];
    headerView.backgroundColor = [UIColor blackColor];

    return headerView;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 45;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.theLegitArrayOfEverything.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    StreamTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];

    cell.theImageView.tag = indexPath.section;
    cell.likeButton.tag = indexPath.section;
    cell.likedImageView.hidden = YES;
    cell.commentButton.tag = indexPath.section;

    IndividualEventPhoto *individualEventPhoto = [self.theLegitArrayOfEverything objectAtIndex:indexPath.section];

//    //number of likes
//    cell.numberOfLikesLabel.text = [NSString stringWithFormat:@"%lu likes", (unsigned long)individualEventPhoto.likes.count];
//
//    ///need to requery and down below actually add the count
//    ///this isn't cutting it, so just query here again for the count of the likes- it's quick- do like above

    PFRelation *relation2 = [individualEventPhoto.object relationForKey:@"likeActivity"];
    PFQuery *query2 = [relation2 query];
    [query2 countObjectsInBackgroundWithBlock:^(int number, NSError *error)
    {
        cell.numberOfLikesLabel.text = [NSString stringWithFormat:@"%i likes", number];
    }];

    [individualEventPhoto.photo getDataInBackgroundWithBlock:^(NSData *data, NSError *error)
     {
         if (!error)
         {
             UIImage *temporaryImage = [UIImage imageWithData:data];
             cell.theImageView.image = temporaryImage;
         }
     }];

    //checking to see if current user has liked photo
    UIImage *btnImage = [UIImage imageNamed:@"like_unselected"];
    [cell.likeButton setImage:btnImage forState:UIControlStateNormal];

    for (PFObject *object in individualEventPhoto.likes)
    {
        NSString *fromUserObjectId = [[object objectForKey:@"fromUser"] objectId];
        NSString *currentUser = [[PFUser currentUser] objectId];

        if ([fromUserObjectId isEqualToString:currentUser])
        {
            UIImage *btnImage = [UIImage imageNamed:@"like_selected"];
            [cell.likeButton setImage:btnImage forState:UIControlStateNormal];
            break;
        }
    }

    //double tap to like
    if (cell.theImageView.gestureRecognizers.count == 0)
    {
        UITapGestureRecognizer *tapping = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapTap:)];
        tapping.numberOfTapsRequired = 2;
        [cell.theImageView addGestureRecognizer:tapping];
        cell.theImageView.userInteractionEnabled = YES;
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}

#pragma mark - Tap Gesture Recognizer

- (void)tapTap:(UITapGestureRecognizer *)tapGestureRecognizer
{
    UIImageView *sender = (UIImageView *)tapGestureRecognizer.view;

    IndividualEventPhoto *individualEventPhoto = [self.theLegitArrayOfEverything objectAtIndex:sender.tag];
    PFUser *picturePhotographer = [individualEventPhoto.object objectForKey:@"photographer"];

    PFObject *like = [PFObject objectWithClassName:@"LikeActivity"];
    like[@"fromUser"] = [PFUser currentUser];
    like[@"toUser"] = picturePhotographer;
    like[@"photo"] = individualEventPhoto.object;
    [like saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
     {
         PFRelation *relation = [individualEventPhoto.object relationforKey:@"likeActivity"];
         [relation addObject:like];
         [individualEventPhoto.object saveInBackground];
     }];

    StreamTableViewCell *cell = (id)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:sender.tag]];

    UIImage *btnImage = [UIImage imageNamed:@"like_selected"];
    [cell.likeButton setImage:btnImage forState:UIControlStateNormal];

    //increment count
    NSString *numberOfLikesString = cell.numberOfLikesLabel.text;
    NSInteger numberOfLikesInt = [numberOfLikesString integerValue];
    numberOfLikesInt++;
    cell.numberOfLikesLabel.text = [NSString stringWithFormat:@"%li likes", (long)numberOfLikesInt];

//    PFRelation *relation = [individualEventPhoto.object relationForKey:@"likeActivity"];
//    PFQuery *query1 = [relation query];
//    [query1 countObjectsInBackgroundWithBlock:^(int number, NSError *error)
//     {
//        cell.numberOfLikesLabel.text = [NSString stringWithFormat:@"%i likes", number];
//     }];


    cell.likedImageView.hidden = NO;
    cell.likedImageView.alpha = 0;

    [UIView animateWithDuration:0.3 animations:^{
        cell.likedImageView.alpha = 1;
    } completion:^(BOOL finished) {
        [UIView animateKeyframesWithDuration:0.3 delay:0.75 options:0 animations:^{
            cell.likedImageView.alpha = 0;
        } completion:^(BOOL finished) {
            cell.likedImageView.hidden = YES;
        }];
    }];
}

#pragma mark - Helper Method

- (void)cameraSetUp
{
    self.cameraController = [[UIImagePickerController alloc] init];
    self.cameraController.delegate = self;
    self.cameraController.allowsEditing = YES;
    self.cameraController.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
    self.cameraController.videoMaximumDuration = 11;
}

#pragma mark - Image Picker

- (IBAction)onPickerButtonTapped:(id)sender
{
    [self cameraSetUp];

    self.cameraController.sourceType = UIImagePickerControllerSourceTypeCamera;

    [self presentViewController:self.cameraController animated:NO completion:^{
        //
    }];
}

- (IBAction)onPhotoLibraryButtonTapped:(id)sender
{
    [self cameraSetUp];

    self.cameraController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;

    [self presentViewController:self.cameraController animated:YES completion:^{
        //
    }];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:^
     {
         //back to StreamEventViewController
     }];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:^{

        //NEED TO FIGURE OUT HOW TO SAVE VIDEOS DIFFERENTLY- THIS MIGHT BE TRICKY
        UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];

        CGSize sacleSize = CGSizeMake(320, 320);
        UIGraphicsBeginImageContextWithOptions(sacleSize, NO, 0.0);
        [image drawInRect:CGRectMake(0, 0, sacleSize.width, sacleSize.height)];
        UIImage * resizedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        NSData *imageData = UIImageJPEGRepresentation(resizedImage, 0.05f);
        PFFile *imageFile = [PFFile fileWithData:imageData];

        // Save PFFile
        [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
         {
             if (!error) {

                 PFObject *photoTaken = [PFObject objectWithClassName:@"Photo"];
                 [photoTaken setObject:imageFile forKey:@"photo"];
                 [photoTaken setObject:[PFUser currentUser] forKey:@"photographer"];
//                 photoTaken[@"caption"] = //

                 [photoTaken saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
                  {
                      if (!error) {

                          PFRelation *relation = [self.event relationforKey:@"eventPhotos"];
                          [relation addObject:photoTaken];
                          [self.event saveInBackground];

                          //[self dismissViewControllerAnimated:NO completion:nil];

                          [self.tableView reloadData];
                      }
                      else {
                          NSLog(@"Error");
                      }
                  }];
             }
         }];
    }];
}

#pragma mark - Segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ToCommentViewControllerSegue"])
    {
        CommentsViewController *commentsViewController = segue.destinationViewController;
        commentsViewController.individualEventPhoto = self.individualEventPhoto;
    }
}

- (IBAction)unwindSegueToStreamEventViewController:(UIStoryboardSegue *)sender
{

}


#pragma mark - Pull To Refresh

- (void)refresh:(UIRefreshControl *)refreshControl
{
    [self queryForImages];
    [self performSelector:@selector(stopRefresh) withObject:nil afterDelay:2.0];
}

- (void)stopRefresh
{
    [self.refreshControl endRefreshing];
}

@end















//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    StreamTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    //    cell.theImageView.tag = indexPath.section;
    //    cell.likeButton.tag = indexPath.section;
    //    cell.likedImageView.hidden = YES;
    //    cell.commentButton.tag = indexPath.section;
    //
    //    //getting the number of likes for each photo
    //    PFQuery *query = [PFQuery queryWithClassName:@"LikeActivity"];
    //    PFObject *object = [self.pictureAndVideoArray objectAtIndex:indexPath.section];
    //    [query whereKey:@"photo" equalTo:object];
    //    [query includeKey:@"fromUser"];
    //
    //    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
    //     {
    //
    //         for (PFObject *object in objects)
    //         {
    //             NSString *objectID = [[object objectForKey:@"fromUser"] objectId];
    //             NSString *currentUserID = [[PFUser currentUser] objectId];
    //
    //             if ([currentUserID isEqualToString:objectID])
    //             {
    //                 //this means user likes the photo
    //                 UIImage *btnImage = [UIImage imageNamed:@"like_selected"];
    //                 [cell.likeButton setImage:btnImage forState:UIControlStateNormal];
    //                 cell.ifLiked = YES;
    //
    //
    //             } else {
    //                 UIImage *btnImage = [UIImage imageNamed:@"like_unselected"];
    //                 [cell.likeButton setImage:btnImage forState:UIControlStateNormal];
    //                 cell.ifLiked = NO;
    //             }
    //         }
    //
    //
    //          cell.numberOfLikesLabel.text = [NSString stringWithFormat:@"%lu likes", (unsigned long)objects.count];
    //     }];
    //
    //    PFFile *file = [object objectForKey:@"photo"];
    //
    //    [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error)
    //     {
    //         if (!error)
    //         {
    //             UIImage *temporaryImage = [UIImage imageWithData:data];
    //             cell.theImageView.image = temporaryImage;
    //         }
    //         else {
    //             NSLog(@"Alert!");
    //         }
    //     }];
    //
    //    //double tap to like
    //    if (cell.theImageView.gestureRecognizers.count == 0)
    //    {
    //        UITapGestureRecognizer *tapping = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapTap:)];
    //        tapping.numberOfTapsRequired = 2;
    //        [cell.theImageView addGestureRecognizer:tapping];
    //        cell.theImageView.userInteractionEnabled = YES;
    //    }
    //    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
//    return cell;
//}

//-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
//{
//    CGRect frame = tableView.frame;
//
//    PFObject *object = [self.pictureAndVideoArray objectAtIndex:section];
//    PFUser *user = [object objectForKey:@"photographer"];
//
//
//    //setting time top right
//
//    NSDate *timeOfPicture = [object valueForKey:@"createdAt"];
//
//    int seconds = -(int)[timeOfPicture timeIntervalSinceNow];
//    int minutes = seconds/60;
//
//   UILabel *timeInterval = [[UILabel alloc] initWithFrame:CGRectMake(230, 5, 100, 30)];
//    timeInterval.textColor = [UIColor whiteColor];
//
//        if (minutes < 60)
//        {
//            timeInterval.text = [NSString stringWithFormat:@"%im", minutes];
//
//        } else if (minutes > 60 && minutes < 1440)
//        {
//            minutes = minutes/60;
//
//            timeInterval.text = [NSString stringWithFormat:@"%ih", minutes];
//
//        } else {
//
//            minutes = minutes/1440;
//            timeInterval.text = [NSString stringWithFormat:@"%id", minutes];
//        }
//
//    //setting the username
//    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(50, 5, 100, 30)];
//    title.text = [NSString stringWithFormat:@"%@", user.username];
//    title.textColor = [UIColor whiteColor];
//
//    PFFile *userProfilePhoto = [user objectForKey:@"userProfilePhoto"];
//    UIImageView *customImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 5, 30, 30)];
//    [userProfilePhoto getDataInBackgroundWithBlock:^(NSData *data, NSError *error)
//     {
//         if (!error)
//         {
//             UIImage *image = [UIImage imageWithData:data];
//             customImageView.image = image;
//             customImageView.layer.cornerRadius = customImageView.bounds.size.width/2;
//             customImageView.layer.borderColor = [[UIColor colorWithRed:202/255.0 green:250/255.0 blue:53/255.0 alpha:1] CGColor];
//             customImageView.layer.borderWidth = 2.0;
//             customImageView.layer.masksToBounds = YES;
//         } else {
//             customImageView.backgroundColor = [UIColor purpleColor];
//         }
//     }];
//
//    //TRY TO SET THIS HEADERVIEW TO "STREAM_BLUR_IMAGE"
//    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
//    headerView.alpha = .7;
//    [headerView addSubview:title];
//    [headerView addSubview:timeInterval];
//    [headerView addSubview:customImageView];
//    headerView.backgroundColor = [UIColor blackColor];
//
//    return headerView;
//}

//- (void)tapTap:(UITapGestureRecognizer *)tapGestureRecognizer
//{
//    UIImageView *sender = (UIImageView *)tapGestureRecognizer.view;
//
//    PFObject *object = [self.pictureAndVideoArray objectAtIndex:sender.tag];
//    PFUser *picturePhotographer = [object objectForKey:@"photographer"];
//
//    PFObject *like = [PFObject objectWithClassName:@"LikeActivity"];
//    like[@"fromUser"] = [PFUser currentUser];
//    like[@"toUser"] = picturePhotographer;
//    like[@"photo"] = object;
//    [like saveInBackground];
//
//    StreamTableViewCell *cell = (id)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:sender.tag]];
//
//    UIImage *btnImage = [UIImage imageNamed:@"like_selected"];
//    [cell.likeButton setImage:btnImage forState:UIControlStateNormal];
//
//    //increment count
//    NSString *numberOfLikesString = cell.numberOfLikesLabel.text;
//    NSInteger numberOfLikesInt = [numberOfLikesString integerValue];
//    numberOfLikesInt++;
//    cell.numberOfLikesLabel.text = [NSString stringWithFormat:@"%li likes", (long)numberOfLikesInt];
//
//    cell.likedImageView.hidden = NO;
//
//    cell.likedImageView.alpha = 0;
//
//    [UIView animateWithDuration:0.3 animations:^{
//        cell.likedImageView.alpha = 1;
//    } completion:^(BOOL finished) {
//        [UIView animateKeyframesWithDuration:0.3 delay:0.75 options:0 animations:^{
//            cell.likedImageView.alpha = 0;
//        } completion:^(BOOL finished) {
//            cell.likedImageView.hidden = YES;
//        }];
//    }];
//}
