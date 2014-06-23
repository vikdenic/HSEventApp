//
//  CreateEventViewController.m
//  With_v0
//
//  Created by Vik Denic on 6/15/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import "CreateEventViewController.h"
#import <Parse/Parse.h>
#import "ChooseEventLocationViewController.h"
#import "DateAndTimeViewController.h"
#import "GKImagePicker.h"

@interface CreateEventViewController () <UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, GKImagePickerDelegate>

@property (nonatomic, strong) IBOutlet UIImageView *themeImageView;
//@property (weak, nonatomic) IBOutlet UITextView *titleTextView;
@property (strong, nonatomic) IBOutlet UITextField *titleTextField;
@property (strong, nonatomic) IBOutlet UITextView *detailsTextView;
@property (weak, nonatomic) IBOutlet UILabel *changeThemeButton;
@property (weak, nonatomic) IBOutlet UIButton *dateAndTimeButton;
@property (weak, nonatomic) IBOutlet UIButton *locationButton;
@property (weak, nonatomic) IBOutlet UIButton *invitePeopleButton;

@property (weak, nonatomic) IBOutlet UIView *dateAndTimeView;

@property UIImagePickerController *cameraController;
@property UIImage *themeImagePicked;
@property PFFile *themeImagePicker;
@property (weak, nonatomic) IBOutlet UILabel *detailsPlaceholderLabel;
@property (weak, nonatomic) IBOutlet UILabel *placeholderLabel;


@property (nonatomic, strong) GKImagePicker *imagePicker;
@property (nonatomic, strong) UIPopoverController *popoverController;


@end

@implementation CreateEventViewController

@synthesize imagePicker;
@synthesize popoverController;


- (void)viewDidLoad
{
    [super viewDidLoad];

    //Vik
    self.eventName = @"Location";
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

//    Vik: we will nil these properties on Create button tapped
//    self.themeImageView.image = nil;
//    self.titleTextView.text = nil;
//    self.titleTextField.text = nil;
//    self.detailsTextView.text = nil;

    self.dateAndTimeView.alpha = 0;
    self.dateAndTimeView.hidden = YES;

    //UIImagePicker Stuff
    self.cameraController = [[UIImagePickerController alloc] init];
    self.cameraController.delegate = self;
    self.cameraController.allowsEditing = YES;
    self.cameraController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;

    //tap on themImageView to open Image Picker
    UITapGestureRecognizer *tapping = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapTap:)];
    tapping.numberOfTapsRequired = 1;
    [self.themeImageView addGestureRecognizer:tapping];
    self.themeImageView.userInteractionEnabled = YES;

    //Vik: sets button text to selected foursquare location
    if(![self.eventName isEqual:@""])
    {
        NSString *locationName = [NSString stringWithFormat:@"           %@",self.eventName];

        [self.locationButton setTitle:locationName forState:UIControlStateNormal];
    }
    else if (!self.eventName)
    {
        [self.locationButton setTitle:@"          Location" forState:UIControlStateNormal];
    }

    //Vik: sets the date & time button text
    if(self.dateString)
    {
    NSString *formattedDateString = [NSString stringWithFormat:@"           %@",self.dateString];

    [self.dateAndTimeButton setTitle:formattedDateString forState:UIControlStateNormal];
    }
    else{
    [self.dateAndTimeButton setTitle:@"          Date and Time" forState:UIControlStateNormal];
    }
}

#pragma mark - Action Methods

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

//- (IBAction)onDateAndTimeButtonTapped:(id)sender
//{
//    [self animatePopUpShow];
//}

- (IBAction)onLocationButtonTapped:(id)sender
{
    //fourSquare API? what else
}

- (IBAction)onInvitePeopleButtonTapped:(id)sender
{
    //modally brings up all of the users friends and they can tap them to invite
}
- (IBAction)onCreateButtonTapped:(id)sender
{
    //if statement here requiring certain fields

    PFObject *event = [PFObject objectWithClassName:@"Event"];
//    event[@"title"] = self.titleTextView.text;
    event[@"title"] = self.titleTextField.text;
    event[@"details"] = self.detailsTextView.text;

    event[@"location"] = self.eventName;

    PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:self.coordinate.latitude
                                                  longitude:self.coordinate.longitude];
    event[@"locationGeoPoint"] = geoPoint;

    event[@"themeImage"] = self.themeImagePicker;
    event[@"creator"] = [PFUser currentUser];
    event[@"eventDate"] = self.dateString;
    [event saveInBackground];

    //takes user back to home page
    [self.tabBarController setSelectedIndex:0];

    //erases event forms
    self.themeImageView.image = nil;
    self.titleTextField.text = nil;
    self.detailsTextView.text = nil;
    self.locationButton.titleLabel.text = @"           Location";
//    self.dateAndTimeButton.titleLabel.text = nil;
}

#pragma mark - Date and Time View Animation


#pragma mark - Tap Gesture Recognizer

- (void)tapTap:(UITapGestureRecognizer *)tapGestureRecognizer
{
//    [self presentViewController:self.cameraController animated:NO completion:nil];
    self.imagePicker = [[GKImagePicker alloc] init];
    self.imagePicker.cropSize = CGSizeMake(320, 160);
    self.imagePicker.delegate = self;

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {

        self.popoverController = [[UIPopoverController alloc] initWithContentViewController:self.imagePicker.imagePickerController];
        [self.popoverController presentPopoverFromRect:tapGestureRecognizer.view.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];

    } else {

        [self presentModalViewController:self.imagePicker.imagePickerController animated:YES];

    }
}

#pragma mark - Image Picker

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:^{
        //back to Create Events View Controller
    }];
}

#pragma mark - Theme Image View Tapped
//going to put a tap gesture on this so that when the user taps it, modally a view controller comes up that allows the user to select photos from their library to put in as the theme photo
//might have some sizing issues and stuff here

-(void)imagePicker:(GKImagePicker *)imagePicker pickedImage:(UIImage *)image
{
    self.themeImageView.image = image;
    [self hideImagePicker];
}

- (void)hideImagePicker{
    if (UIUserInterfaceIdiomPad == UI_USER_INTERFACE_IDIOM()) {

        [self.popoverController dismissPopoverAnimated:YES];

    } else {

        [self.imagePicker.imagePickerController dismissViewControllerAnimated:YES completion:nil];
    }
}

//-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
//{
//    [picker dismissViewControllerAnimated:NO completion:^{
//
//        self.themeImagePicked = [info valueForKey:UIImagePickerControllerOriginalImage];
//        //here I should resize the image to the size of the imageView so it looks good and normal before saving it?
//        //maybe this might make it weird in the other image views it goes in
//
//        CGSize scaledSize = CGSizeMake(320, 160);
//        UIGraphicsBeginImageContextWithOptions(scaledSize, NO, 2.0);
//
//        [self.themeImagePicked drawInRect:(CGRect){.size = scaledSize}];
//        UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
//        UIGraphicsEndImageContext();
//
//        self.themeImageView.image = resizedImage;
//
//        NSData *themeImageData = UIImagePNGRepresentation(self.themeImagePicked);
//        self.themeImagePicker = [PFFile fileWithData:themeImageData];
//
//        if (self.themeImageView.image)
//        {
//            self.changeThemeButton.hidden = YES;
//        }
//        [self dismissViewControllerAnimated:NO completion:nil];
//    }];
//}

#pragma mark - Text View

// Replicates Placeholder with label
- (IBAction)onTitleTextViewDidBeginEditing:(id)sender
{
    self.placeholderLabel.hidden = YES;
}

- (IBAction)onTitleTextViewDidChange:(id)sender
{
    self.placeholderLabel.hidden = ([self.titleTextField.text length] > 0);
}

- (IBAction)onTitleTextViewDidEnd:(id)sender
{
    self.placeholderLabel.hidden = ([self.titleTextField.text length] > 0);
}


-(void)textViewDidBeginEditing:(UITextView *)textView
{
    self.detailsPlaceholderLabel.hidden = YES;
}

//this could be an issue
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {

    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }

    return YES;
}

#pragma mark - Segues
//NEED TO HOOK UP SEGUE FROM CHOOSELOCATION SELECTED CELL
-(IBAction)unwindChooseLocationToCreateEvent:(UIStoryboardSegue *)sender
{
    ChooseEventLocationViewController *chooseVC = sender.sourceViewController;
    self.eventName = chooseVC.eventName;
    self.coordinate = chooseVC.coordinate;
    NSLog(@"CREATE: %f %f",self.coordinate.latitude, self.coordinate.longitude);
}

-(IBAction)unwindDateToCreate:(UIStoryboardSegue *)sender
{
    DateAndTimeViewController *dateVC = sender.sourceViewController;
    self.dateString = dateVC.dateString;
//    self.dateAndTimeButton.titleLabel.text = [NSString stringWithFormat:@"           %@",self.dateString];
}

@end
