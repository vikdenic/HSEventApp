//
//  ExploreSwiftViewController.swift
//  With_v0
//
//  Created by Richard Fellure on 7/10/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

import UIKit

class ExploreSwiftViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    var locationManager = CLLocationManager()
    var location = CLLocation()
    var eventObjects = [PFObject]()
    var comparisonExploreAnnotationArray = [AnyObject]()
    var eventObject = PFObject()

    @IBOutlet var imageView: UIImageView
    @IBOutlet var mapView: MKMapView
    @IBOutlet var titleLabel: UILabel
    @IBOutlet var locationLabel: UILabel
    @IBOutlet var individualEventView: UIView
    @IBOutlet var dateLabel: UILabel

    override func viewDidLoad() {
        super.viewDidLoad()

        let mapTap = UITapGestureRecognizer(target: self, action: "theMapTap")
        mapTap.numberOfTapsRequired = 1
        mapView.addGestureRecognizer(mapTap)
        mapView.userInteractionEnabled = true

        individualEventView.hidden = true
        navigationController.navigationBarHidden = true

    }

    override func viewWillAppear(animated: Bool)
    {
        viewWillAppear(true)

        locationManager.delegate = self
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }

    func queryForEvents(userGeoPoint: PFGeoPoint)
    {
        let query = PFQuery(className: "Event")
        query.includeKey("creator")

        query.whereKey("locationGeoPoint", nearGeoPoint: userGeoPoint, withinMiles: 20)
        query.findObjectsInBackgroundWithBlock({objects, error in

            for object in objects
            {
                self.eventObjects += object as (PFObject)
            }
            for objct in self.eventObjects
            {
                let exploreAnnotation = ExploreAnnotationSwift()
                exploreAnnotation.geoPoint = objct.objectForKey("locationGeoPoint") as PFGeoPoint
                exploreAnnotation.coordinate = CLLocationCoordinate2DMake(exploreAnnotation.geoPoint.latitude, exploreAnnotation.geoPoint.longitude)
                exploreAnnotation.title = objct.objectForKey("title") as String
                exploreAnnotation.details = objct.objectForKey("details") as String
                exploreAnnotation.object = objct
                exploreAnnotation.creator = objct.objectForKey("creator") as PFUser
                exploreAnnotation.location = objct.objectForKey("location") as String
                exploreAnnotation.date = objct.objectForKey("eventDate") as String

                exploreAnnotation.creatorImageFile = objct.objectForKey("creator").objectForKey("userProfilePhoto") as PFFile

                exploreAnnotation.creatorImageFile.getDataInBackgroundWithBlock({data, error in
                    exploreAnnotation.creatorImage = UIImage(data: data)
                    self.comparisonExploreAnnotationArray += exploreAnnotation
                    self.mapView.addAnnotation(exploreAnnotation)
                    })
                exploreAnnotation.themeFile = objct.objectForKey("mapThemeImage") as PFFile
                exploreAnnotation.themeFile.getDataInBackgroundWithBlock({data, error in
                    exploreAnnotation.themeImage = UIImage(data: data)
                    self.comparisonExploreAnnotationArray += exploreAnnotation
                    self.mapView.addAnnotation(exploreAnnotation)
                    })
            }

            })
    }

    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!)
    {
        locationManager.stopUpdatingLocation()
        mapView.showsUserLocation = true

        location = locationManager.location

        let userGeoPoint = PFGeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)

        queryForEvents(userGeoPoint)

        //causes the zooming in to be delayed
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ({
            NSThread.sleepForTimeInterval(1.3)
            dispatch_async(dispatch_get_main_queue(), ({
                self.delayForZoom()
                }))
            }))
    }

    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView!
    {
        if annotation.isKindOfClass(MKUserLocation)
        {
            return nil
        }

        let exploreAnnotation = annotation as ExploreAnnotationSwift

        let annotationView = ExploreEventAnnotationView(annotation: exploreAnnotation, reuseIdentifier: nil)

        annotationView.image = exploreAnnotation.creatorImage

        return annotationView
    }

    func delayForZoom()
    {
        var mapRegion : MKCoordinateRegion = MKCoordinateRegionMake(location.coordinate, MKCoordinateSpanMake(0.10, 0.10))
       mapView.setRegion(mapRegion, animated: true)

    }

    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!)
    {
        println("Change location in simulator \(error)")
    }


    func theMapTap(tapGestureRecognizer: UITapGestureRecognizer)
    {
        individualEventView.hidden = true

    }


}
