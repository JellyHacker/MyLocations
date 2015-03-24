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
        
        startLocationManager()
        updateLabels()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabels()
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
                    statusMessage = "Error Getting Location"
                }
            } else if !CLLocationManager.locationServicesEnabled() { statusMessage = "Location Services Disabled"
            } else if updatingLocation { statusMessage = "Searching..."
            } else {
                statusMessage = "Tap 'Get My Location' to Start"
            }
            messageLabel.text = statusMessage
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
        
        lastLocationError = nil
        location = newLocation
        updateLabels()
    }
}

