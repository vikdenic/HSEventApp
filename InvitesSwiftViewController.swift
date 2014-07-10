//
//  InvitesSwiftViewController.swift
//  With_v0
//
//  Created by Richard Fellure on 7/9/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//



import UIKit

extension Array{
    func changeNSArray(anNSArray: NSArray) ->Array
    {
        return anNSArray as Array
    }
}

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
        var cell: InvitesTableViewCell = tableView.dequeueReusableCellWithIdentifier("Cell") as InvitesTableViewCell
        var event = eventArray[indexPath.row]
        var eventInvite = eventInviteArray[indexPath.row]
        
        var userProfilePic: PFFile! = event.objectForKey("creator").objectForKey("userProfilPhoto") as PFFile
        userProfilePic.getDataInBackgroundWithBlock({data, error in
            if data == nil
            {
                cell.creatorImageView.image = nil
            }
            else
            {
                var temporaryImage = UIImage(data: data)

                cell.creatorImageView.layer.cornerRadius = cell.creatorImageView.bounds.size.width/2
//                cell.creatorImageView.layer.borderColor = UIColor(red: 202/255.0, green: 250/255.0, blue: 53/255.0, alpha: 1.0) 
                cell.creatorImageView.layer.borderWidth = 2.0
                cell.creatorImageView.layer.masksToBounds = true

                cell.creatorImageView.image = temporaryImage
            }
            })

        var file: PFFile! = event.objectForKey("themeImage") as PFFile
        file.getDataInBackgroundWithBlock({data, error in
            var image = UIImage(data: data)
            cell.themeImageView.image = image
            })

        var userName: String! = event.objectForKey("creator").objectForKey("username") as String
        cell.creatorNameLabel.text = userName as String

        cell.eventNameLabel.text = event["title"] as String
        cell.eventDateLabel.text = event["eventDate"] as String
        cell.accessoryType = UITableViewCellAccessoryType.None

        var yesButton = UIImage(named: "yes_image_unselected")
        cell.yesButton.setImage(yesButton, forState: UIControlState.Normal)
        cell.yesButton.eventObject = event
        cell.yesButton.tag = indexPath.row
        cell.yesButton.eventInviteObject = eventInvite
//        cell.yesButton.addTarget(self, action: onYesTapped, forControlEvents: UIControlEvents.TouchUpInside)

        var noButton = UIImage(named: "no_image_unselected")
        cell.noButton.setImage(noButton, forState: UIControlState.Normal)
        cell.noButton.eventObject = event
        cell.noButton.eventInviteObject = eventInvite
        cell.noButton.tag = indexPath.row
//        cell.noButton.addTarget(self, action: onNoTapped, forControlEvents: UIControlEvents.TouchUpInside)

        return cell
    }

    func tableView(tableView: UITableView!, didDeselectRowAtIndexPath indexPath: NSIndexPath!)
    {

    }

}
