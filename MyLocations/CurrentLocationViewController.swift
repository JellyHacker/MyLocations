//
//  FirstViewController.swift
//  MyLocations
//
//  Created by Brandon Evans on 3/20/15.
//  Copyright (c) 2015 Vicinity inc. All rights reserved.
//

import UIKit
import CoreLocation

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate {

    // The CLLocationManager is the object that will give you the GPS coordinates.
    let locationManager = CLLocationManager()
    // You will store the user’s current location in this variable.  This needs to be an optional, because it is possible to not have a location, for example when you’re stranded out in the Sahara desert somewhere and there is not a cell tower or GPS satellite in sight (it happens).
    var location: CLLocation?
    var updatingLocation = false
    var lastLocationError: NSError?
    
    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    var performingReverseGeocoding = false
    var lastGeocodingError: NSError?
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    
    //This method is hooked up to the Get My Location button. It tells the location manager that the view controller is its delegate and that you want to receive locations with an accuracy of up to ten meters. Then you start the location manager. From that moment on the CLLocationManager object will send location updates to its delegate, i.e. the view controller.
    @IBAction func getLocation() {
        
        let authStatus: CLAuthorizationStatus = CLLocationManager.authorizationStatus()
        
        // This checks the current authorization status. If it is .NotDetermined, meaning that this app has not asked for permission yet, then the app will request “When In Use” authorization. That allows the app to get location updates while it is open and the user is interacting with it.
        if authStatus == .NotDetermined {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        
        // This shows the alert if the authorization status is denied or restricted.
        if authStatus == .Denied || authStatus == .Restricted {
            showLocationServicesDeniedAlert()
            return
        }
        
        if updatingLocation {
            stopLocationManager()
        } else {
            location = nil
            lastLocationError = nil
            placemark = nil
            lastGeocodingError = nil
            startLocationManager()
        }
        updateLabels()
        configureGetButton()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabels()
        configureGetButton()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // This pops up an alert with a helpful hint. This app is pretty useless without access to the user’s location, so it should encourage the user to enable location services. It’s not necessarily the user of the app who has denied access to the location data; a systems administrator or parent may have restricted location access.
    func showLocationServicesDeniedAlert() {
        
        let alert = UIAlertController(title: "Location Services Disabled", message: "Please enable location services for this app in Settings.", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        
        alert.addAction(okAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func updateLabels() {
        
        // If there is a valid location object, you convert the latitude and longitude, which are values with type Double, into strings and put them into the labels.
        if let location = location {
            // This creates a new String object using the format string "%.8f", and the value to replace in that string, location.coordinate.latitude.  Placeholders always start with a % percent sign. Examples of common placeholders are: %d for integer values, %f for decimals, and %@ for arbitrary objects.  The .8 means that there should always be 8 digits behind the decimal point.
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
            longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
            tagButton.hidden = false
            messageLabel.text = ""
            
            // Because you only do the address lookup once the app has a location, this if/else block only needs to be inside the if and not the else.  If you’ve found an address, you show that to the user, otherwise you show a status message.
            if let placemark = placemark {
                addressLabel.text = stringFromPlacemark(placemark)
            } else if performingReverseGeocoding {
                addressLabel.text = "Searching for Address..."
            } else if lastGeocodingError != nil {
                addressLabel.text = "Error Finding Address"
            } else {
                addressLabel.text = "No Address Found"
            }
        } else {
            latitudeLabel.text = ""
            longitudeLabel.text = ""
            addressLabel.text = ""
            tagButton.hidden = true
            messageLabel.text = "Tap 'Get My Location' to Start"
            
            // This determines what to put in the messageLabel at the top of the screen. It uses a bunch of if-statements to figure out what the current status of the app is.  If the location manager gave an error, the label will show an error message.
            var statusMessage: String
            
            if let error = lastLocationError {
                // the user has not given this app permission to use the location services
                if error.domain == kCLErrorDomain && error.code == CLError.Denied.rawValue {
                    statusMessage = "Location Services Disabled"
                } else {
                    // If the error code is something else then you simply say “Error Getting Location” as this usually means there was no way of obtaining a location fix.
                    statusMessage = "Error Getting Location"
                }
            } else if !CLLocationManager.locationServicesEnabled() {
                // Even if there was no error it might still be impossible to get location coordinates if the user disabled Location Services completely on her device (instead of just for this app). You check for that situation with the locationServicesEnabled() method of CLLocationManager.
                statusMessage = "Location Services Disabled"
            } else if updatingLocation {
                statusMessage = "Searching..."
            } else {
                statusMessage = "Tap 'Get My Location' to Start"
            }
            messageLabel.text = statusMessage
        }
    }
    
    func stringFromPlacemark(placemark: CLPlacemark) -> String {
        
        // subThoroughfare is the house number
        // thoroughfare is the street name
        // locality is the city
        // administrativeArea is the state or province
        // postalCode is the zip code or postal code.
        return "\(placemark.subThoroughfare) \(placemark.thoroughfare)\n" +
                "\(placemark.locality) \(placemark.administrativeArea) " +
                "\(placemark.postalCode)"
    }
    
    func startLocationManager() {
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
        }
    }
    
    func stopLocationManager() {
        
        if updatingLocation {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
        }
    }

    // MARK:
    /*
    CLLocationManagerDelegate Methods
    */

    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        
        println("didFailWithError: \(error)")
        
        if error.code == CLError.LocationUnknown.rawValue {
            return
        }
        lastLocationError = error
        
        stopLocationManager()
        updateLabels()
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        
        let newLocation = locations.last as CLLocation
        println("didUpdateLocations \(newLocation)")
        
        /*
        If the time at which the location object was determined is too long ago (5 seconds in this case), then this is a so-called cached result.
        Instead of returning a new location fix, the location manager may initially give you the most recently found location under the assumption that you might not have moved much since last time (obviously this does not take into consideration people with jet packs).
        You’ll simply ignore these cached locations if they are too old.
        */
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            return
        }
            
        /*
        To determine whether new readings are more accurate than previous ones you’re going to be using the horizontalAccuracy property of the location object. However, sometimes locations may have a horizontalAccuracy that is less than 0, in which case these measurements are invalid and you should ignore them.
        */
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        
        // This calculates the distance between the new reading and the previous reading, if there was one.  If there was no previous reading, then the distance is DBL_MAX. That is a built-in constant that represents the maximum value that a floating-point number can have.  This guarantees that other distance calculations will work even if a true distance wasn't able to be calculated yet.
        var distance = CLLocationDistance(DBL_MAX)
        if let location = location {
            distance = newLocation.distanceFromLocation(location)
        }
        
        /*
        This is where you determine if the new reading is more useful than the previous one. Generally speaking, Core Location starts out with a fairly inaccurate reading and then gives you more and more accurate ones as time passes. However, there are no guarantees so you cannot assume that the next reading truly is always more accurate.
        Note that a larger accuracy value means less accurate – after all, accurate up to 100 meters is worse than accurate up to 10 meters. That’s why you check whether the previous reading, location!.horizontalAccuracy, is greater than the new reading, newLocation.horizontalAccuracy.
        You also check for location == nil. Recall that location is the optional instance variable that stores the CLLocation object that you obtained in a previous call to didUpdateLocations. If location is nil then this is the very first location update you’re receiving and in that case you should also continue.
        So if this is the very first location reading (location is nil) or the new location is more accurate than the previous reading, you go on.
        */
        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
                
            /*
            You’ve seen this before. It clears out any previous error if there was one and stores the new location object into thelocation variable.
            */
            lastLocationError = nil
            location = newLocation
            updateLabels()
        
            
            /*
            If the new location’s accuracy is equal to or better than the desired accuracy, you can call it a day and stop asking the location manager for updates. When you started the location manager in startLocationManager(), you set the desired accuracy to 10 meters (kCLLocationAccuracyNearestTenMeters), which is good enough for this app.
            */
            if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
                println("*** We're done!")
                stopLocationManager()
                configureGetButton()
                // This forces a reverse geocoding for the final location, even if the app is already currently performing another geocoding request.
                if distance > 0 {
                    performingReverseGeocoding = false
                }
            }
            // The app should only perform a single reverse geocoding request at a time, so first you check whether it is not busy yet by looking at the performingReverseGeocoding variable. Then you start the geocoder.
            if !performingReverseGeocoding {
                println("*** Going to Geocode")
                performingReverseGeocoding = true
                
                // When the geocoder finds a result for the location object that you gave it, it invokes the closure and executes the statements within. The placemarks parameter will contain an array of CLPlacemark objects that describe the address information, and the error variable contains an error message in case something went wrong.
                geocoder.reverseGeocodeLocation(location, completionHandler: {
                    placemarks, error in
                    println("*** Found placemarks: \(placemarks), error: \(error)")
                    self.lastGeocodingError = error
                    
                    if error == nil {
                        self.placemark = placemarks.last as? CLPlacemark
                    } else {
                        // If an error occurred during Geocoding.  You don’t want to show an old address, only the address that corresponds to the current location or no address at all.
                        self.placemark = nil
                    }
                    
                    self.performingReverseGeocoding = false
                    self.updateLabels()
                })
            } else if distance < 1.0 {
                // If the coordinate from this reading is not significantly different from the previous reading and it has been more than 10 seconds since you’ve received that original reading, then it’s a good point to hang up your hat and stop.
                let timeInterval = newLocation.timestamp.timeIntervalSinceDate(location!.timestamp)
                
                if timeInterval > 10 {
                    println("*** Force done!")
                    stopLocationManager()
                    updateLabels()
                    configureGetButton()
                }
            }
        }
    }
    
    func configureGetButton() {
        
        if updatingLocation {
            getButton.setTitle("Stop", forState: .Normal)
        } else {
            getButton.setTitle("Get My Location", forState: .Normal)
        }
    }
    
    
    
    
    
    
    
    
    
    
    
}

