//
//  KeyAnnotation.swift
//  bitcoinGO
//
//  Created by Jason Crouse on 6/12/18.
//  Copyright © 2018 Jason Crouse. All rights reserved.
//

import UIKit
import MapKit

class KeyAnnotation: NSObject, MKAnnotation {
	
	let coordinate: CLLocationCoordinate2D
	let title: String?
	var captured = false
	
	init(coordinate: CLLocationCoordinate2D, title: String?) {
		self.coordinate = coordinate
		self.title = title
		super.init()
	}

}
