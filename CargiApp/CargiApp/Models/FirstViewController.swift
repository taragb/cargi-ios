//
//  FirstViewController.swift
//  Cargi
//
//  Created by Ishita Prasad on 4/19/16.
//  Copyright © 2016 Cargi. All rights reserved.
//

import UIKit
import GoogleMaps
import CoreBluetooth
import MessageUI
import EventKit
import QuartzCore
import SpeechKit

class FirstViewController: UIViewController, SKTransactionDelegate, CLLocationManagerDelegate, CBCentralManagerDelegate, MFMessageComposeViewControllerDelegate {
    
    @IBOutlet var mapView: GMSMapView!
    
    // Types of Maps that can be used.
    private enum MapsType {
        case Apple // Apple Maps
        case Google // Google Maps
    }
    
    private var defaultMap: MapsType = MapsType.Google // hard-coded to Google Maps, but may change depending on user's preference.
    
    var data: NSMutableData = NSMutableData()
    
    @IBOutlet weak var destLabel: UILabel!
    @IBOutlet weak var addrLabel: UILabel!
    @IBOutlet weak var eventLabel: UILabel!
    @IBOutlet weak var destinationView: UIView!
    
    @IBOutlet weak var navigateButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var textButton: UIButton!
    @IBOutlet weak var gasButton: UIButton!
    @IBOutlet weak var musicButton: UIButton!
    @IBOutlet var dashboardView: UIView!
    
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var contactLabel: UILabel!
    @IBOutlet weak var listenButton: UIButton!
    @IBOutlet weak var eventButton: UIButton!
    @IBOutlet weak var searchButton: UIButton!
    
    var locationManager = CLLocationManager()
    var gasFinder = GasFinder()
    var didFindMyLocation = false // avoid unnecessary location updates
    let defaultLatitude: CLLocationDegrees = 37.426
    let defaultLongitude: CLLocationDegrees = -122.172
    
    var destLocation: String?
    var destinationName: String?
    var destCoordinates = CLLocationCoordinate2D()
    
    
    var manager: CBCentralManager! // Bluetooth Manager
    var currentEvent: EKEvent? {
        didSet {
            eventLabel.text = currentEvent?.title
        }
    }
    
    var eventDirectory = EventDirectory()
    
    var contactDirectory = ContactDirectory()
    var contact: String? {
        didSet {
            contactLabel.text = contact
            if contact == nil {
                callButton.enabled = false
                textButton.enabled = false
            } else {
                callButton.enabled = true
                textButton.enabled = true
            }
        }
    }
    var contactNumbers: [String]?
    
    var directionTasks = DirectionTasks() // Google Directions
    var syncRouteSuccess: Bool = false
    var destMarker = GMSMarker()
    var routePolyline = GMSPolyline() // lines that will show the route.
    var routePolylineBorder = GMSPolyline()
    var routePath = GMSPath()
    
    var distanceTasks = DistanceMatrixTasks()

    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        destMarker.icon = UIImage(named: "destination_icon")
        view.sendSubviewToBack(mapView)
    
        // Observer for changes in myLocation of google's map view
        mapView.addObserver(self, forKeyPath: "myLocation", options: NSKeyValueObservingOptions.New, context: nil)
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        
        mapView.settings.compassButton = true
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let client = delegate.client!
        let item = ["text":"Awesome item"]
        let itemTable = client.tableWithName("TodoItem")
        itemTable.insert(item) {
            (insertedItem, error) in
            if error != nil{
                print("Error" + error!.description);
            } else {
                print("Item inserted, id: " + String(insertedItem!["id"]))
            }
        }
        
        //        let deviceID = UIDevice.currentDevice().identifierForVendor!.UUIDString
        
        //        let db = AzureDatabase()
        //        db.initializeUserID(deviceID) { (status, success) in
        //            if (success) {
        //                print(db.userID)
        //
        //            } else {
        //                print(status)
        //            }
        //
        //        }
        
        resetData()
        syncData()
        
        //        db.insertEvent()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(animated: Bool){
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    
    /// When the app starts, update the maps view so that it shows the user's current location in the center.
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if !didFindMyLocation {
            let myLocation: CLLocation = change![NSKeyValueChangeNewKey] as! CLLocation
            if !syncRouteSuccess {
                mapView.camera = GMSCameraPosition.cameraWithTarget(myLocation.coordinate, zoom: 15.0)
            }
            didFindMyLocation = true
        }
    }
    
    /// Reset Data
    func resetData() {
        self.contact = nil
        self.eventLabel.text = nil
        self.destLabel.text = nil
        self.addrLabel.text = nil
       
        self.destLocation = nil
        self.destinationName = nil
        mapView.clear()
    }
    
    /// Sync with Apple Calendar to get the current calendar event, and update the labels given this event's information.
    func syncData() {
        let contacts = contactDirectory.getAllPhoneNumbers()
        guard let events = eventDirectory.getAllCalendarEvents() else { return }
        
        for ev in events {
            guard let _ = ev.location else { continue } // ignore event if it has no location info.
            self.currentEvent = ev
            for contact in contacts.keys {
                if ev.title.rangeOfString(contact) != nil {
                    if contact.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) != "" {
                        self.contact = contact
                        break
                    }
                }
            }
            if contact != nil { break }
        }
        
        if contact == nil {
            for ev in events {
                if !ev.allDay {
                    self.currentEvent = ev
                }
            }
        }
        
        contactNumbers = contactDirectory.getPhoneNumber(contact)
        
        guard let ev = currentEvent else { return }
        print(ev.eventIdentifier)
        
        destLocation = ev.location
        if let checkIfEmpty = ev.location {
            if checkIfEmpty.isEmpty {
                destLocation = nil
            }
        }
        
        if let coordinate = ev.structuredLocation?.geoLocation?.coordinate {
            destCoordinates = coordinate
        }
        
        if let loc = ev.location {
            let locArr = loc.characters.split { $0 == "\n" }.map(String.init)
            if locArr.count > 1 {
                destLabel.text = locArr.first
                addrLabel.text = locArr[1]
            } else {
                destLabel.text = locArr.first
                addrLabel.text = nil
            }
            destinationName = locArr.first
        }
        print("showroute")
        showRoute(showDestMarker: true)
    }
    
    /**
     Open Google Maps showing the route to the given coordinates.
     */
    func openGoogleMapsLocation(coordinate: CLLocationCoordinate2D) {
        UIApplication.sharedApplication().openURL(NSURL(string: "comgooglemaps://?saddr=&daddr=\(coordinate.latitude),\(coordinate.longitude)&directionsmode=driving")!)
    }
    
    
    /**
     Open Google Maps showing the route to the given address.
     */
    func openGoogleMapsLocationAddress(address: String) {
        let path = "comgooglemaps://saddr=&?daddr=\(address)&directionsmode=driving"
        print(path)
        guard let url = NSURL(string: path) else { return }
        UIApplication.sharedApplication().openURL(url)
    }
    
    /**
     Open Apple Maps showing the route to the given coordinates.
     */
    func openAppleMapsLocation(coordinate: CLLocationCoordinate2D) {
        guard let query = currentEvent?.location else { return }
        let address = query.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet())!
        let near = "\(coordinate.latitude),\(coordinate.longitude)"
        let path = "http://maps.apple.com/?q=\(address)&near=\(near)"
        guard let url = NSURL(string: path) else { return }
        UIApplication.sharedApplication().openURL(url)
    }
    
    /**
     Open Apple Maps showing the route to the given address.
     */
    func openAppleMapsLocationAddress(address: String) {
        let path = "http://maps.apple.com/?daddr=\(address)&dirflg=d"
        guard let url = NSURL(string: path) else { return }
        UIApplication.sharedApplication().openURL(url)
    }
    
    /**
     Open Maps, given the current event's location.
     */
    func openMaps() {
        //        guard let ev = currentEvent else { return }
        //        let queries = ev.location!.componentsSeparatedByString("\n")
        //        print(queries)
        guard let dest = destLocation else {
            showAlertViewController(title: "Error", message: "No destination specified.")
            return
        }
        let query = dest.componentsSeparatedByString("\n").joinWithSeparator(" ")
        print(query)
        let address = query.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet())!
        
        if self.defaultMap == MapsType.Google && UIApplication.sharedApplication().canOpenURL(NSURL(string: "comgooglemaps://")!) {
            self.openGoogleMapsLocationAddress(address)
        } else if UIApplication.sharedApplication().canOpenURL(NSURL(string: "http://maps.apple.com/")!) {
            self.openAppleMapsLocationAddress(address)
        }
        
        /* Only if Geocoder is needed */
        /*
         switch CLLocationManager.authorizationStatus() {
         case .AuthorizedAlways, .AuthorizedWhenInUse:
         let geocoder = LocationGeocoder()
         geocoder.getCoordinates(ev.location!) { (status, error) in
         guard let coordinate = geocoder.coordinate else {
         print(error)
         return
         }
         // Use Google Maps if it exists. Otherwise, use Apple Maps.
         print(ev.location!)
         if self.defaultMap == MapsType.Google && UIApplication.sharedApplication().canOpenURL(NSURL(string: "comgooglemaps://")!) {
         self.openGoogleMapsLocation(coordinate)
         } else if UIApplication.sharedApplication().canOpenURL(NSURL(string: "http://maps.apple.com/")!) {
         self.openAppleMapsLocation(coordinate)
         }
         }
         default: break
         }
         */
    }
    
    /// Location is updated.
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("updating location")
    }
    
    
    
    func showRouteWithWaypoints(waypoints waypoints: [String]!, showDestMarker: Bool) {
        mapView.clear()
        routePolyline.path = nil
        routePolylineBorder.path = nil
        
        guard let originLocation = locationManager.location?.coordinate else {
            syncRouteSuccess = false
            return
        }
        let origin = "\(originLocation.latitude),\(originLocation.longitude)"
        
        self.directionTasks.getDirections(origin, dest: destLocation, waypoints: waypoints) { (status, success) in
            print("got directions")
            self.destMarker.map = nil
            self.syncRouteSuccess = success
            if success {
                print("success")
                if showDestMarker {
                    self.configureMap()
                }
                self.drawRoute()
            } else {
                self.showAlertViewController(title: "Error", message: "Can't find a way there.")
                print(status)
            }
        }
    }
    
    /// Update the Google Maps view with the synced route, depending on whether we've successfully received the response from Google Directions API.
    func showRoute(showDestMarker showDestMarker: Bool) {
        showRouteWithWaypoints(waypoints: nil, showDestMarker: showDestMarker)
    }
    
    /// Shows a pin at the destination on the map.
    private func configureMap() {
        destMarker.position = directionTasks.destCoordinate
        destMarker.map = mapView
        print(destMarker.position)
        print("configure maps done")
    }
    
    
    /// Draws the route using polylines obtained from Google Directions.
    private func drawRoute() {
        let route = self.directionTasks.overviewPolyline["points"] as! String
        
        // Draw the path
        let path: GMSPath = GMSPath(fromEncodedPath: route)!
        routePolyline.path = path
        routePolyline.map = mapView
        routePolyline.strokeColor = UIColor(red: 109/256, green: 180/256, blue: 245/256, alpha: 1.0)
        routePolyline.strokeWidth = 4.0
        routePolyline.zIndex = 10
        
        // Draw the border around the path
        routePolylineBorder.path = path
        routePolylineBorder.strokeColor = UIColor.blackColor()
        routePolylineBorder.strokeWidth = routePolyline.strokeWidth + 0.5
        routePolylineBorder.zIndex = routePolyline.zIndex - 1
        routePolylineBorder.map = mapView
        print("drawmaps done")
        
        let bounds = GMSCoordinateBounds(path: path)
        let cameraUpdate = GMSCameraUpdate.fitBounds(bounds, withEdgeInsets: UIEdgeInsets(top: 165.0, left: 20.0, bottom: 165.0, right: 20.0))
        mapView.moveCamera(cameraUpdate)
    }
    
    
    /// Starts a phone call with the first phone number in the given list of phone numbers.
    func callPhone(phoneNumbers: [String]?) {
        guard let numbers = phoneNumbers else { return }
        let number = numbers[0] as NSString
        let charactersToRemove = NSCharacterSet.alphanumericCharacterSet().invertedSet
        let numberToCall = number.componentsSeparatedByCharactersInSet(charactersToRemove).joinWithSeparator("")
        
        let stringURL = "tel://\(numberToCall)"
        print(stringURL)
        guard let url = NSURL(string: stringURL) else { return }
        UIApplication.sharedApplication().openURL(url)
    }
    
    
    /// Opens up a message view with a preformatted message that shows destination and ETA.
    func sendETAMessage(phoneNumbers: [String]?) {
        guard let numbers = phoneNumbers else { return }
        guard let _ = destLocation else { return }
        let locValue: CLLocationCoordinate2D = locationManager.location!.coordinate
        if (MFMessageComposeViewController.canSendText()) {
            let controller = MFMessageComposeViewController()
            let firstName = self.contact?.componentsSeparatedByString(" ").first
            print(contact)
            print(firstName)
            distanceTasks.getETA(locValue.latitude, origin2: locValue.longitude, dest1: destCoordinates.latitude, dest2: destCoordinates.longitude) { (status, success) in
                print(status)
                if success {
                    let duration = self.distanceTasks.durationInTrafficText
                    if let dest = self.destinationName {
                        controller.body = "Hi \(firstName!), I will arrive at \(dest) in \(duration)."
                    } else {
                        controller.body = "Hi \(firstName!), I will arrive in \(duration)."
                    }
                    print(controller.body)
                } else {
                    self.showAlertViewController(title: "Error", message: "No ETA found.")
                }
            }
            print(phoneNumbers)
            controller.recipients = [numbers[0]] // Send only to the primary number
            print(controller.recipients)
            controller.messageComposeDelegate = self
            print("presenting view controller")
            self.presentViewController(controller, animated: true, completion: nil)
        }
    }
    
    //Temporary Azure REST API Test
    func azureRESTAPITest() {
        let stringURL = "https://cargiios.azure-mobile.net/api/calculator/add?a=1&b=5"
        print(stringURL)
        guard let url = NSURL(string: stringURL) else { return }
        
        dispatch_async(dispatch_get_main_queue()) {
            let data = NSData(contentsOfURL: url)
            
            // Convert JSON response into an NSDictionary.
            var json: [NSObject:AnyObject]?
            do {
                json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as? [NSObject:AnyObject]
            } catch {
                //completionHandler(status: "", success: false)
            }
            //            print(json!.description)
            
            guard let dict = json else { return }
            let result = dict["result"]
            print(result)
        }
    }
    
    /// Show location on the Google Maps view if the user has given the app access to user's location.
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.AuthorizedWhenInUse {
            mapView.myLocationEnabled = true
        }
    }
    
    /// Close the message view screen once the message is sent.
    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        //... handle sms screen actions
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    /// Print all contacts in text format to the console.
    private func printContacts() {
        // Print all the contacts
        let contacts = contactDirectory.getAllPhoneNumbers()
        for (contact, numbers) in contacts {
            for number in numbers {
                print(contact + ": " + number)
            }
        }
    }
    
    /// Print all events in text format to the console.
    private func printEvents() {
        // Print all events in calendars.
        guard let events = eventDirectory.getAllCalendarEvents() else { return }
        for ev in events {
            print("EVENT: \(ev.title)" )
            print("\t-startDate: \(ev.startDate)" )
            print("\t-endDate: \(ev.endDate)" )
            if let location = ev.location {
                print("\t-location: \(location)")
            }
            print("\n")
        }
    }
    
    /// Print all reminders in text format to the console.
    private func printReminders() {
        // Print all reminders
        let reminders = eventDirectory.getAllReminders()
        print("REMINDERS:")
        print(reminders?.description)
    }
    
    
    // MARK: Core Bluetooth Manager Methods
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        print("Peripheral: \(peripheral)")
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("didConnectPeripheral")
        print(peripheral.description)
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        print("Checking")
        switch(central.state)
        {
        case.Unsupported:
            print("BLE is not supported")
        case.Unauthorized:
            print("BLE is unauthorized")
        case.Unknown:
            print("BLE is Unknown")
        case.Resetting:
            print("BLE is Resetting")
        case.PoweredOff:
            print("BLE service is powered off")
        case.PoweredOn:
            print("BLE service is powered on")
            print("Start Scanning")
            manager.scanForPeripheralsWithServices(nil, options: nil)
        }
    }
    
    func showAlertViewController(title title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let alertAction = UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(alertAction)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    
    // MARK: IBAction Methods
    
    /// Refresh Button Clicked
    
    @IBAction func refreshButtonClicked(sender: UIButton) {
        resetData()
        syncData()
    }
    
    /// Navigate Button clicked.
    @IBAction func navigateButtonClicked(sender: UIButton) {
        if let _ = currentEvent {
            openMaps()
        } else {
            syncData()
            openMaps()
        }
    }
    
    //Start session for voice capture/recognition
    @IBAction func listenButtonClicked(sender: AnyObject) {
        print("listening for voice command");
        listenButton.setTitle("Listening...", forState: .Normal)
        let url = "nmsps://NMDPTRIAL_team_cargi_co20160418020749@sslsandbox.nmdp.nuancemobility.net:443"
        let token = "6ff1671b87d0259dc04a734edbf2ab4894184242e68c4cf3fac45545c7c10e37b376523a4677d706c14a549c3cffe5d0182713feb35ff2ad2447f2eb090122bc"
        let session = SKSession(URL: NSURL(string: url), appToken: token)
        session.recognizeWithType(SKTransactionSpeechTypeDictation,
                                  detection: .Short,
                                  language: "eng-USA",
                                  delegate: self)
    }
    
    //find the best result and start gas action if it matches
    func transaction(transaction: SKTransaction!, didReceiveRecognition recognition: SKRecognition!) {
        print("Result of Speech Recognition: " + recognition.text)
        if (recognition.text.lowercaseString.rangeOfString("gas") != nil) {
            gasButtonClicked(nil)
        }
        if (recognition.text.lowercaseString.rangeOfString("music") != nil) {
            musicButtonClicked(nil)
        }
        if (recognition.text.lowercaseString.rangeOfString("call") != nil) {
            phoneButtonClicked(nil)
        }
        if (recognition.text.lowercaseString.rangeOfString("text") != nil) {
            messageButtonClicked(nil)
        }
        listenButton.setTitle("Listen", forState: .Normal)
    }
    
    /// Gas Button clicked
    @IBAction func gasButtonClicked(sender: UIButton?) {
        //        azureRESTAPITest()
        print("gas button activated");
        guard let originLocation = locationManager.location?.coordinate else {
            return
        }
        
        let origin = "\(originLocation.latitude),\(originLocation.longitude)"
        print("origin: \(origin)")
        gasFinder.getNearbyGas(origin) { (status: String, success: Bool) in
            if success {
                print(self.gasFinder.stationName)
                print(self.gasFinder.coordinates)
                if self.destLocation != nil {
                    self.showRouteWithWaypoints(waypoints: ["place_id:\(self.gasFinder.placeID)"], showDestMarker: true)
                } else {
                    self.destLocation = self.gasFinder.address
                    self.showRoute(showDestMarker: false)
                }
                let marker = GMSMarker(position: self.gasFinder.coordinates)
                marker.appearAnimation = kGMSMarkerAnimationPop
                marker.title = self.gasFinder.stationName
                marker.snippet = self.gasFinder.address
                marker.map = self.mapView
            } else {
                print("Error: \(status)")
            }
        }
    }
    
    /// Send Message Button clicked.
    @IBAction func messageButtonClicked(sender: UIButton?) {
        print("message button activated")
        self.sendETAMessage(self.contactNumbers)
    }
    

    /// Starts a phone call using the phone number associated with current event.
    @IBAction func phoneButtonClicked(sender: UIButton?) {
        print("phone button activated")
        self.callPhone(contactNumbers)
    }
    
    /// Opens the Apple Calendar app, using deep-linking.
    @IBAction func eventButtonClicked(sender: UIButton) {
        let appName: String = "calshow"
        let appURL: String = "\(appName):"
        if UIApplication.sharedApplication().canOpenURL(NSURL(string: appURL)!) {
            print(appURL)
            UIApplication.sharedApplication().openURL(NSURL(string: appURL)!)
        }
    }
    
    /// Opens the music app of preference, using deep-linking.
    // Music app options: Spotify (default) and Apple Music
    @IBAction func musicButtonClicked(sender: UIButton?) {
        print("music button activated")
        let appName: String = "spotify"
        
        let appURL: String = "\(appName)://spotify:user:spotify:playlist:5FJXhjdILmRA2z5bvz4nzf"
        if (UIApplication.sharedApplication().canOpenURL(NSURL(string: appURL)!)) {
            print(appURL)
            UIApplication.sharedApplication().openURL(NSURL(string: appURL)!)
        } else {
            print("Can't use spotify://")
            let appName: String = "music"
            let appURL: String = "\(appName)://"
            if (UIApplication.sharedApplication().canOpenURL(NSURL(string: appURL)!)) {
                print(appURL)
                UIApplication.sharedApplication().openURL(NSURL(string: appURL)!)
            }
        }
    }
    
    
    /// Search Button clicked
    @IBAction func searchButtonClicked(sender: UIButton) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        let visibleRegion = self.mapView.projection.visibleRegion()
        autocompleteController.autocompleteBounds = GMSCoordinateBounds(
            coordinate: visibleRegion.farLeft, coordinate: visibleRegion.nearRight)
        self.presentViewController(autocompleteController, animated: true, completion: nil)
    }
    
}

// Extension for using the Google Places API.
extension FirstViewController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(viewController: GMSAutocompleteViewController, didAutocompleteWithPlace place: GMSPlace) {
        print("Place name: \(place.name)")
        print("Place address: \(place.formattedAddress)")
        print("Place attributions: \(place.attributions)")
        print("Place coordinates: \(place.coordinate)")
        self.dismissViewControllerAnimated(true, completion: nil)
        self.destLocation = place.formattedAddress
        self.destinationName = place.name
        self.destCoordinates = place.coordinate
        self.destLabel.text = place.name
        self.addrLabel.text = place.formattedAddress
        self.eventLabel.text = nil
        self.showRoute(showDestMarker: true)
        //        mapView.camera = GMSCameraPosition.cameraWithTarget(place.coordinate, zoom: 12)
        //        let marker = GMSMarker(position: place.coordinate)
        //        marker.title = place.name
        //        marker.map = mapView
    }
    
    func viewController(viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: NSError) {
        // TODO: handle the error.
        print("Error: \(error.description)", terminator: "")
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // User canceled the operation.
    func wasCancelled(viewController: GMSAutocompleteViewController) {
        print("Autocomplete was cancelled.", terminator: "")
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}