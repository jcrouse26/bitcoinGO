/*
//
////
////////
////////////
////////////////
//////// Copyright
//// Jason Crouse
/ 2 /\ 0 /\ 1 /\ 8 /
/ 0 /
/ 1 /
/ 8 /
*/



import UIKit
import MapKit
import CoreLocation
import ARKit
import GeoFire
import Firebase
import FirebaseDatabase

class MapViewController: UIViewController {
	
	@IBOutlet weak var mapView: MKMapView!
	var winnings : [String] = []
	let locationManager = CLLocationManager()
	var userLocation: CLLocation?
	var targets = [ARItem]()
	var previousDegrees : Double = -75 // set heading for WNW
	var didSetUserLocation = false
	var didReceiveUserLocation = false
	
	// This is for database
	var ref : DatabaseReference!
	var geoFire: GeoFire?
	var geoFireForPins: GeoFire?
	
	
	var geoFireRef: DatabaseReference?
	var usersRef: DatabaseReference?
	var pinsRef: DatabaseReference?
	var keyRef: DatabaseReference?
	
	
	var startingCoordinate = CLLocationCoordinate2D(latitude: 37.805345, longitude: -122.511065)
	let endingCoordinateX = CLLocationCoordinate2D(latitude: 37.805345, longitude: -122.387910)
	let endingCoordinateY = CLLocationCoordinate2D(latitude: 37.729987, longitude: -122.511065)
	
	@IBOutlet weak var winningsLabel: UILabel!
	
	let belcher : CLLocation = CLLocation(latitude: 37.768360, longitude: -122.430378)
	
	func setupLocations() {
		// IMPORTANT: Item descriptions must be unique
		let firstTarget : ARItem?
		if let userLocation = self.userLocation, didSetUserLocation == false {
			firstTarget = ARItem(itemDescription: "Pin \(self.winnings.count + 1)", location: userLocation, itemNode: nil)
			targets.append(firstTarget!)
			didSetUserLocation = true
			
			// In this loop you iterate through all items inside the targets array and add an annotation for each target.
			for item in targets {
				let annotation = MapAnnotation(location: item.location.coordinate, item: item)
				if !winnings.contains(annotation.item.itemDescription) {
					self.mapView.addAnnotation(annotation)
				}
			}
		}
	}
	
	func setupPinsEverywhere() {
		// .075358 == amount of degrees moved vertically / 205 == .000368 *2 == 0.000736
		// .123155 == amount of degrees moved horizontally / 205 == .000601 *2 == 0.001202
		
		keyRef = Database.database().reference().child("keys")
		geoFireForPins = GeoFire(firebaseRef: keyRef!)
		//keyRef?.removeValue()
		
	
		/*var j = 0
		while j < 100 {
			var i = 0
			var annotation = KeyAnnotation(coordinate: startingCoordinate, title: "key\(i+1, j+1)")
			while i < 100 {
				annotation = KeyAnnotation(coordinate: startingCoordinate, title: "key\(i+1, j+1)")
				//self.mapView.addAnnotation(annotation)
				
				//geoFireForPins?.setLocation(CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude), forKey: annotation.title!)
				startingCoordinate.longitude += 0.001202
				i += 1
			}
			startingCoordinate.longitude = -122.511065
			startingCoordinate.latitude -= 0.000736
			//annotation = KeyAnnotation(coordinate: startingCoordinate, title: "key\(i+1, j+1)")
			//self.mapView.addAnnotation(annotation)
			j += 1
		}*/
		
		
		
	}
	
	func showKeysOnMap(location: CLLocation) {
		keyRef = Database.database().reference().child("keys")
		geoFireForPins = GeoFire(firebaseRef: keyRef!)
		
		let circleQuery = geoFireForPins!.query(at: location, withRadius: 0.3)
		_ = circleQuery.observe(GFEventType.keyEntered, with: { (key, location) in
			let anno = KeyAnnotation(coordinate: location.coordinate, title: key)
			self.mapView.addAnnotation(anno)
		})
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		mapView.userTrackingMode = MKUserTrackingMode.followWithHeading
		
		if CLLocationManager.authorizationStatus() == .notDetermined {
			locationManager.requestWhenInUseAuthorization()
		}
		
		
		// This is for Geofire/Firebase database
		ref = Database.database().reference()
		let userID = Auth.auth().currentUser!.uid
		geoFireRef = Database.database().reference().child("users")
		usersRef = geoFireRef?.child("\(userID)")
		pinsRef = usersRef?.child("Pins")
		
		geoFire = GeoFire(firebaseRef: pinsRef!)
		retrieveGeofireSnapshot()
		
		setupPinsEverywhere()
	}
	
	func retrieveGeofireSnapshot() {
		// Check in with GeoFire for updated win counts
		pinsRef!.observe(.value) { (snapshot) in
			self.winnings = []
			for _ in snapshot.children {
				self.winnings.append(snapshot.key)
			}
			// Now that we have a view of the snapshot of the data
			// Update text
			self.winningsLabel.text = String(snapshot.childrenCount)
			// Update pin
			self.setupLocations()
		}
	}
}

extension MapViewController: MKMapViewDelegate {
	
	func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
		self.userLocation = userLocation.location
		didReceiveUserLocation = true
		if self.userLocation != nil {
			showKeysOnMap(location: self.userLocation!)
		}
		
	}
	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		var keyView: MKAnnotationView
		var view: MKPinAnnotationView
		var annotationView: MKAnnotationView
		
		let keyIdentifier = "key"
		let coinIdentifier = "coin"
		
		if annotation.isMember(of: MKUserLocation.self) {
			annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "User")
			annotationView.image = UIImage(named: "user")
			let transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
			annotationView.transform = transform
			// return annotationView for custom user image
			return nil
		} else if annotation.isMember(of: KeyAnnotation.self) {
			annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: keyIdentifier)
			annotationView.image = UIImage(named: "key")
			let transform = CGAffineTransform(scaleX: 0.05, y: 0.05)
			annotationView.transform = transform
			return annotationView
		} else if annotation.isMember(of: MapAnnotation.self) {
			guard let annotation = annotation as? MapAnnotation else {
				return nil
			}
			if annotation.captured == false {
				annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: coinIdentifier)
				annotationView.image = UIImage(named: "coin")
				let transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
				annotationView.transform = transform
				return annotationView
			} else {
				annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "pin")
				annotationView.image = UIImage(named: "x")
				return annotationView
			}
		}
		return nil
	}
	
	func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
		
		// Return and deselect if user has selected "My Location" instead of a pin
		if view.annotation?.title! == "My Location" {
			self.mapView.deselectAnnotation(view.annotation, animated: true)
			mapView.userTrackingMode = MKUserTrackingMode.followWithHeading
			return
		}
		if view.reuseIdentifier! == "pin" {
			// create an alert saying you've already won
			// let alert = UIAlertController(title: "Nice Try!", message: "You already collected this one. Get off your ass and collect a new one.", preferredStyle: UIAlertControllerStyle.alert)
			
			// alert.addAction(UIAlertAction(title: "I'm sorry, won't happen again", style: UIAlertActionStyle.default, handler: { (alert: UIAlertAction!) in }))
			// self.present(alert, animated: true)
			
			// deselect this pin and return
			self.mapView.deselectAnnotation(view.annotation, animated: true)
			return
		}
		
		
		// Here you get the coordinate of the selected annotation.
		let coordinate = view.annotation!.coordinate
		
		// Make sure the optional userLocation is populated.
		if let userCoordinate = userLocation {
			
			// Make sure the tapped item is within range of the users location.
			if userCoordinate.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) <= 4500 {
				// Add to array of winnings
				
				if let title = view.annotation!.title! {
					// If we wanted to do an AR Screen... we'd do it here
					// For now... just let the homies get their prize... FOR FREE!
					
					winnings.append(title)
					winningsLabel.text = String(winnings.count)
					
					
					self.geoFire?.setLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude), forKey: "\(title)")

					
					// Add vibration so John's ladies can truly enjoy BitcoinGO ;)
					AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
					
					// create next object
					
					// Do some math to come up with next point, based on current point and previous path
					let currentLat = coordinate.latitude
					let currentLong = coordinate.longitude
					let multiplier = 0.00135 // this is approximately 150 meters
					let randDegrees = Double(arc4random_uniform(180)) - 90
					let nextCoordinateLat = currentLat + multiplier*__cospi((randDegrees + previousDegrees)/180)
					let nextCoordinateLong = currentLong + multiplier*__sinpi((randDegrees + previousDegrees)/180)
					
					// Put the pieces together to do the appropriate adding/removing of pins on the map, and CHANGE COLOR
					let newTarget = ARItem(itemDescription: "Pin \(winnings.count + 1)", location: CLLocation(latitude: nextCoordinateLat, longitude: nextCoordinateLong), itemNode: nil)
					let newAnnotation = MapAnnotation(location: newTarget.location.coordinate, item: newTarget)
					self.mapView.addAnnotation(newAnnotation)
					
					// Some math to ensure proper bearing for next time
					previousDegrees = randDegrees + previousDegrees
					
					// Attempt to create it as a MapAnnotation (custom class)
					guard let annotation = view.annotation as? MapAnnotation else { return }
					annotation.captured = true
					
					// Remove and add new annotation to map
					self.mapView.removeAnnotation(view.annotation!)
					self.mapView.addAnnotation(annotation)
					
				}
				
			} else if userCoordinate.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) > 40 {
				let distance = Int(userCoordinate.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)))
				let alert = UIAlertController(title: "Sorry", message: "You are \(distance) meters away. That's too far to get rich. Don't be lazy!", preferredStyle: UIAlertControllerStyle.alert)
				
				alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.default, handler: { (alert: UIAlertAction!) in }))
				self.present(alert, animated: true)
				
			}
			self.mapView.deselectAnnotation(view.annotation, animated: true)
		}
		mapView.userTrackingMode = MKUserTrackingMode.followWithHeading
	}
	
}

