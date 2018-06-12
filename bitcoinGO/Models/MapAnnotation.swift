//
//  MapAnnotation.swift
//  AR_Hunt
//
//  Created by Jason Crouse on 6/1/18.
//
//

import MapKit
import Firebase

class MapAnnotation: NSObject, MKAnnotation {
	
	// The protocol requires a variable coordinate and an optional title.
	let coordinate: CLLocationCoordinate2D
	let title: String?
	var captured = false
	// Here you store the ARItem that belongs to the annotation.
	let item: ARItem
	
	//let someResult: String
	
	// With the init method you can populate all variables.
	init(location: CLLocationCoordinate2D, item: ARItem) {
		self.coordinate = location
		self.item = item
		self.title = item.itemDescription
		
		super.init()
	}
	
	/*init?(snapshot: DataSnapshot) {
		guard
			let value = snapshot.value as? [String: AnyObject],
			let name = value["name"] as? String,
			let addedByUser = value["addedByUser"] as? String,
			let completed = value["completed"] as? Bool else {
				return nil
		}
	
		self.name = name
		self.addedByUser = addedByUser
		self.completed = completed
	}*/
}

