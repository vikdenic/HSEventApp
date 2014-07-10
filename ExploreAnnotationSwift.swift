//
//  ExploreAnnotationSwift.swift
//  With_v0
//
//  Created by Richard Fellure on 7/10/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

import UIKit

class ExploreAnnotationSwift: MKPointAnnotation {

    var geoPoint = PFGeoPoint()

    var details = String()
    var object = PFObject()
    var creator = PFUser()
    var location = String()
    var themeFile = PFFile()
    var themeImage = UIImage()
    var date = String()
    var creatorImageFile = PFFile()
    var creatorImage = UIImage()

}
