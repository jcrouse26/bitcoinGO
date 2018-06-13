//
//  MapAnnotation.swift
//  AR_Hunt
//
//  Created by Jason Crouse on 6/1/18.
//
//

import MapKit
import Firebase

class CoinAnnotation: NSObject, MKAnnotation {
	
	// The protocol requires a variable coordinate and an optional title.
	let coordinate: CLLocationCoordinate2D
	let title: String?
	var captured = false
	
	// With the init method you can populate all variables.
	init(location: CLLocationCoordinate2D, title: String) {
		self.coordinate = location
		self.title = title
		
		super.init()
	}
}

