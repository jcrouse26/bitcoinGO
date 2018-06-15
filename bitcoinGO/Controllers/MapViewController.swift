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

// WARNING: If setInitialCoin fails (ie. userLocation is not set), there's currently no method to set it once user location is found


import UIKit
import MapKit
import CoreLocation
import ARKit
import GeoFire
import Firebase
import FirebaseDatabase

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    var coinWinnings : [CoinAnnotation] = []
    var keyWinnings : [KeyAnnotation] = []
    
    let locationManager = CLLocationManager()
    var userLocation: CLLocation?
    var previousDegrees : Double = -75 // set heading for WNW
    var didSetUserLocation = false
    var didSetInitialCoin = false
    //var didQueryKeys = false
    
    // This is for database
    var ref : DatabaseReference!
    var geoFireForCoins: GeoFire?
    var geoFireForKeys: GeoFire?
    var geoFireForUser: GeoFire?
    
    var geoFireRef: DatabaseReference?
    var usersRef: DatabaseReference?
    var coinsRef: DatabaseReference?
    var keyRef: DatabaseReference?
    var userRef: DatabaseReference?
    
    
    var startingCoordinate = CLLocationCoordinate2D(latitude: 37.770081, longitude: -122.432517)
    let endingCoordinateX = CLLocationCoordinate2D(latitude: 37.805345, longitude: -122.387910)
    let endingCoordinateY = CLLocationCoordinate2D(latitude: 37.729987, longitude: -122.511065)
    
    @IBOutlet weak var winningsLabel: UILabel!
    
    let belcher : CLLocation = CLLocation(latitude: 37.768360, longitude: -122.430378)
    
    
    
    func createKeysInFirebase() {
        // .075358 == amount of degrees moved vertically / 205 == .000368 *2 == 0.000736
        // .123155 == amount of degrees moved horizontally / 205 == .000601 *2 == 0.001202
		
		// setting this again locally, but commenting out
        //keyRef = usersRef?.child("keys")
        //self.geoFireForKeys = GeoFire(firebaseRef: keyRef!)
        
        // This code is needed if pins ever get erased
        var j = 0
        while j < 100 {
            var i = 0
            var annotation = KeyAnnotation(coordinate: startingCoordinate, title: "key\(i+1, j+1)")
            while i < 100 {
                annotation = KeyAnnotation(coordinate: startingCoordinate, title: "key\(i+1, j+1)")
                self.geoFireForKeys?.setLocation(CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude), forKey: annotation.title!)
                startingCoordinate.longitude += 0.001202
                i += 1
            }
            startingCoordinate.longitude = -122.432517
            startingCoordinate.latitude -= 0.000736
            j += 1
        }
    }
    
    func showKeysOnMap(forLocation location: CLLocation) {
        
        let circleQuery = geoFireForKeys!.query(at: location, withRadius: 0.1)
        _ = circleQuery.observe(GFEventType.keyEntered, with: { (key, location) in
            let anno = KeyAnnotation(coordinate: location.coordinate, title: key)
            if self.mapView.annotations.contains(where: { (mka) -> Bool in
                if mka.title == anno.title {
                    return true
                } else {
                    return false
                }
            }) == true {
                
            } else {
                self.mapView.addAnnotation(anno)
            }
            //self.mapView.addAnnotation(anno)
            //self.didSetInitialCoin = true
        })
        _ = circleQuery.observe(GFEventType.keyExited, with: { (key, location) in
            let anno = KeyAnnotation(coordinate: location.coordinate, title: key)
            self.mapView.removeAnnotation(anno)
        })
    
        _ = circleQuery.observeReady {
            //circleQuery.removeAllObservers()
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.userTrackingMode = MKUserTrackingMode.followWithHeading
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.requestAlwaysAuthorization()
        }
        
        // This is for Geofire/Firebase database
        let userID = Auth.auth().currentUser!.uid
        
        geoFireRef = Database.database().reference().child("users")
        usersRef = geoFireRef?.child("\(userID)")
        coinsRef = usersRef?.child("coins")
        keyRef = usersRef?.child("keys")
        userRef = usersRef?.child("user")
        
        geoFireForKeys = GeoFire(firebaseRef: keyRef!)
        geoFireForCoins = GeoFire(firebaseRef: coinsRef!)
        geoFireForUser = GeoFire(firebaseRef: userRef!)
        retrieveGeofireSnapshot()
    
        _ = setInitialCoin()
        createKeysInFirebase()
    }
    
    func retrieveGeofireSnapshot() {
        // Check in with GeoFire for updated coins won
        
        coinsRef!.observe(.value) { (snapshot) in
            
            // Stop geofire retrieval for coins won if new coin has already been set
            if self.didSetInitialCoin == true {
                return
            }
            
            if snapshot.childrenCount == 0 {
                self.didSetInitialCoin = self.setInitialCoin()
            }
            
            // Set local winnings to blank -- NOT SURE THIS IS NECESSARY
            self.coinWinnings = []
            
            // This loop will iterate through each child in the dataset and downcast it as a DataSnapshot
            let enumerator = snapshot.children
            while let rest = enumerator.nextObject() as? DataSnapshot {
            
                self.geoFireForCoins?.getLocationForKey(rest.key, withCallback: { (location, error) in
                    if let location = location {
                        // LocationForKey successful, so create an instance of CoinAnnotation to populate coinWinnings, update label appropriately
                        let anno = CoinAnnotation(location: CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude), title: rest.key)
                        anno.captured = true
                        self.coinWinnings.append(anno)
                        self.winningsLabel.text = String(self.coinWinnings.count)
                        
                        // Check to see if we're on the final child. If so, set initial coin, set bool.
                        // WARNING: IF THIS IS COMPLETED BEFORE USERLOCATION, THIS WILL FAIL
                        if snapshot.childrenCount == self.coinWinnings.count {
                            self.didSetInitialCoin = self.setInitialCoin()
                        }
                        
                    } else if let error = error {
                        print("big time error bro")
                        print(error.localizedDescription)
                    }
                })
            }
        }
    }
    
    // This function is only called from the retreive GeoFireSnapshot function
    func setInitialCoin() -> Bool {
        if let userLocation = self.userLocation {
            let annotation = CoinAnnotation(location: CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude), title: "Pin \(self.coinWinnings.count + 1)")
            self.mapView.addAnnotation(annotation)
            self.didSetInitialCoin = true
            return true
        } else { return false }
    }
    
}




extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
		if let loc = userLocation.location {
			self.userLocation = loc
			self.geoFireForUser?.setLocation(loc, forKey: "location")
			showKeysOnMap(forLocation: loc)
		}
	
        // This fails sometimes. Still unclear how.
		// I think I need some other way of firing the dropInitialCoin from here if it happens to load all data before
		
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
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
        } else if annotation.isMember(of: CoinAnnotation.self) {
            guard let annotation = annotation as? CoinAnnotation else {
                return nil
            }
            if annotation.captured == false {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: coinIdentifier)
                annotationView.image = UIImage(named: "coin")
                let transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
                annotationView.transform = transform
                return annotationView
            } else {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "x")
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
        if view.reuseIdentifier! == "x" {
            // deselect this pin and return
            self.mapView.deselectAnnotation(view.annotation, animated: true)
            return
        }
        
        // Here you get the coordinate of the selected annotation.
        let coordinate = view.annotation!.coordinate
        
        // Make sure the optional userLocation is populated.
        if let userCoordinate = userLocation {
            
            // Make sure the tapped item is within range of the users location.
            if userCoordinate.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) <= 45000 {
                // Add to array of winnings
                
                if let title = view.annotation!.title! {
                    // If we wanted to do an AR Screen, we'd do it here
                    // For now just let the homies get their prize... FOR FREE!

                    // Add vibration so John's ladies can truly enjoy BitcoinGO ;)
                    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
                    
                    if view.annotation! is KeyAnnotation {
                        let newAnno = KeyAnnotation(coordinate: view.annotation!.coordinate, title: view.annotation!.title!)
                        keyWinnings.append(newAnno)
                        self.mapView.removeAnnotation(view.annotation!)
                        self.geoFireForKeys = GeoFire(firebaseRef: keyRef!)
                        self.geoFireForKeys?.setLocation(CLLocation(latitude: 0, longitude: 0), forKey: newAnno.title!)
                        self.geoFireForKeys?.removeKey(newAnno.title!)
                    }
                    
                    guard let annotation = view.annotation as? CoinAnnotation else {
                        print("let annotation as CoinAnnotation failed")
                        return
                    }
                    // Everything here will only run if the above succeeds
                    
                    // Do some math to come up with next point, based on current point and previous path
                    let currentLat = coordinate.latitude
                    let currentLong = coordinate.longitude
                    let multiplier = 0.00135 // this is approximately 150 meters
                    let randDegrees = Double(arc4random_uniform(180)) - 90
                    let nextCoordinateLat = currentLat + multiplier*__cospi((randDegrees + previousDegrees)/180)
                    let nextCoordinateLong = currentLong + multiplier*__sinpi((randDegrees + previousDegrees)/180)
                    let nextCoordinate = CLLocationCoordinate2DMake(nextCoordinateLat, nextCoordinateLong)
                    previousDegrees = randDegrees + previousDegrees
                    
                    annotation.captured = true
                    coinWinnings.append(annotation)
                    winningsLabel.text = String(coinWinnings.count)
                    self.geoFireForCoins?.setLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude), forKey: "\(title)")
                    
                    // Put the pieces together to do the appropriate adding/removing of pins on the map, and change color
                    let newAnnotation = CoinAnnotation(location: nextCoordinate, title: "Pin \(coinWinnings.count + 1)")
                    self.mapView.addAnnotation(newAnnotation)
                    
                    // Add new annotation with captured == true to map, which sets to X
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

