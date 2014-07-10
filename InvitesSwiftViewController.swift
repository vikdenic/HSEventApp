//
//  InvitesSwiftViewController.swift
//  With_v0
//
//  Created by Richard Fellure on 7/9/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//



import UIKit

class InvitesSwiftViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var tableView: UITableView
    var eventArray = [PFObject]()
    var eventInviteArray = [PFObject]()

    override func viewDidLoad()
    {
        super.viewDidLoad()
    }

    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(true)

        queryForEvents()
    }

    func queryForEvents()
    {
        let query = PFQuery(className: "EventInvite")
        query.whereKey("toUser", equalTo: PFUser.currentUser())
        query.whereKey("statusOfUser", equalTo: "Invited")
        query.includeKey("event")
        query.findObjectsInBackgroundWithBlock({objects, error in
            for object in objects
            {
                self.eventInviteArray += object as PFObject

                var theEvent: AnyObject! = object.objectForKey("event")
                var eventID = theEvent.objectId

                var eventQuery = PFQuery(className: "Event")
                eventQuery.includeKey("creator")
                eventQuery.whereKey("objectID", equalTo: eventID)
                eventQuery.getFirstObjectInBackgroundWithBlock({object, error in
                    self.eventArray += object
                    self.tableView.reloadData()
                    })
                }
            })
    }

    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int
    {
        return eventArray.count
    }

    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell!
    {
        let cell: InvitesTableViewCell = tableView.dequeueReusableCellWithIdentifier("Cell") as InvitesTableViewCell
        let event = eventArray[indexPath.row]
        let eventInvite = eventInviteArray[indexPath.row]
        
        let userProfilePic: PFFile! = event.objectForKey("creator").objectForKey("userProfilPhoto") as PFFile
        userProfilePic.getDataInBackgroundWithBlock({data, error in
            if data == nil
            {
                cell.creatorImageView.image = nil
            }
            else
            {
                let temporaryImage = UIImage(data: data)

                cell.creatorImageView.layer.cornerRadius = cell.creatorImageView.bounds.size.width/2
                cell.creatorImageView.layer.borderColor = UIColor(red: 202/255.0, green: 250/255.0, blue: 53/255.0, alpha: 1.0).CGColor
                cell.creatorImageView.layer.borderWidth = 2.0
                cell.creatorImageView.layer.masksToBounds = true

                cell.creatorImageView.image = temporaryImage
            }
            })

        let file: PFFile! = event.objectForKey("themeImage") as PFFile
        file.getDataInBackgroundWithBlock({data, error in
            var image = UIImage(data: data)
            cell.themeImageView.image = image
            })

        let userName: String = event.objectForKey("creator").objectForKey("username") as String
        cell.creatorNameLabel.text = userName

        cell.eventNameLabel.text = event["title"] as String
        cell.eventDateLabel.text = event["eventDate"] as String
        cell.accessoryType = UITableViewCellAccessoryType.None

        let yesButton = UIImage(named: "yes_image_unselected")
        cell.yesButton.setImage(yesButton, forState: UIControlState.Normal)
        cell.yesButton.eventObject = event
        cell.yesButton.tag = indexPath.row
        cell.yesButton.eventInviteObject = eventInvite
        cell.yesButton.addTarget(self, action:"onYesTapped", forControlEvents: UIControlEvents.TouchUpInside)

        let noButton = UIImage(named: "no_image_unselected")
        cell.noButton.setImage(noButton, forState: UIControlState.Normal)
        cell.noButton.eventObject = event
        cell.noButton.eventInviteObject = eventInvite
        cell.noButton.tag = indexPath.row
        cell.noButton.addTarget(self, action:"onNoTapped", forControlEvents: UIControlEvents.TouchUpInside)

        return cell
    }

    func tableView(tableView: UITableView!, didDeselectRowAtIndexPath indexPath: NSIndexPath!)
    {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    func onYesTapped(sender:InvitesButton)
    {
        let cell: InvitesTableViewCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: sender.tag, inSection: 0)) as InvitesTableViewCell

        if sender.imageView.image == UIImage(named: "yes_image_unselected")
        {
            let btnImage = UIImage(named: "yes_image_selected")
            sender.setImage(btnImage, forState: UIControlState.Normal)

            let eventRelation = PFUser.currentUser().relationForKey("eventsAttending")
            eventRelation.addObject(sender.eventObject)
            PFUser.currentUser().saveInBackground()

            sender.eventInviteObject["statusOfUser"] = "Going"
            sender.eventInviteObject.saveInBackground()

            let goingRelation = sender.eventObject.relationForKey("usersAttending")
            goingRelation.addObject(PFUser.currentUser())
            let notGoingRelation = sender.eventObject.relationForKey("usersNotAttending")
            notGoingRelation.removeObject(PFUser.currentUser())
            sender.eventObject.saveInBackground()

            let btnImage2 = UIImage(named: "no_image_unselected")
            cell.noButton.setImage(btnImage2, forState: UIControlState.Normal)
        }
        else if sender.imageView.image == UIImage(named: "yes_image_unselected")
        {
            let btnImage = UIImage(named: "no_image_unselected")
            sender.setImage(btnImage, forState: UIControlState.Normal)

            sender.eventInviteObject["statusOfUser"] = "Invited"
            sender.eventInviteObject.saveInBackground()

            let goingRelation = sender.eventObject.relationForKey("usersAttending")
            goingRelation.removeObject(PFUser.currentUser())
            sender.eventObject.saveInBackground()
        }
    }

    func onNoTapped(sender:InvitesButton)
    {
        let cell: InvitesTableViewCell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: sender.tag, inSection: 0)) as InvitesTableViewCell

        if sender.imageView.image == UIImage(named: "no_image_unselected")
        {
            let btnImage = UIImage(named: "no_image_selected")
            sender.setImage(btnImage, forState: UIControlState.Normal)

            let goingRelation = sender.eventObject.relationForKey("usersAttending")
            goingRelation.removeObject(PFUser.currentUser())
            sender.eventObject.saveInBackground()

            sender.eventInviteObject["statusOfUser"] = "Denied"
            sender.eventInviteObject.saveInBackground()

            let notGoingRelation = sender.eventObject.relationForKey("usersNotAttending")
            notGoingRelation.addObject(PFUser.currentUser())
            sender.eventObject.saveInBackground()

            let btnImage2 = UIImage(named: "yes_image_unselected")
        }

        else if sender.imageView.image == "no_image_selected"
        {
            let btnImage = UIImage(named: "no_image_unselected")
            sender.setImage(btnImage, forState: UIControlState.Normal)

            sender.eventInviteObject["statusOfUser"] = "Invited"
            sender.eventInviteObject.saveInBackground()

            let goingRelation = sender.eventObject.relationForKey("usersNotAttending")
            goingRelation.removeObject(PFUser.currentUser())
            sender.eventObject.saveInBackground()
        }
    }


}
