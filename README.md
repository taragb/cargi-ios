<img src="http://i.imgur.com/Tyx3dLj.png" alt="cargi logo" width="300">

Many tools in our lives are personalized, and we should expect the same things from our cars, considering the amount of time we spend in them. Drivers have varying skills and habits: some might prefer a safe driver mode which allows them to easily switch lanes, guides them into a parking spot, and finds roads where there are fewer cars.  Others might want the radio blasting and mood lighting as they speed down the highway, or want to automatically play their favorite morning radio show on their way to work. We’re really excited to make the car experience something that is more than just about getting from one place to another - the car should feel like an extension of yourself where everything is customized to perfectly meet your needs.

# Getting started:
To run the iOS app, you must import the GoogleMaps framework, which is stored in our Google Drive `6 - Software Demo` due to its large size. Place the GoogleMaps.framework file in `iOS > CargiApp > Pods > GoogleMaps > Frameworks`.

**Important**: Do not use `.xcodeproject` file to open Xcode; use `iOS > CargiApp > CargiApp.xcworkspace` instead.

# Development Milestones (MVP):
- [x] Set up Google Maps view and basic Google Places search
- [x] Compute ETA given origin & destination
- [x] Parse events from Apple Calendar
- [x] Parse reminders from Reminders app
- [x] Set up messages and calling through Cargi
- [x] Set up local notifications
- [ ] [blocked] Experiment with bluetooth connection and automatic app launching (3/8 received iBeacon from Michael and Robert, but need to obtain arduino)
- [x] Redirect to Apple/Google Maps with destination set up using deep linking
- [x] Create and send text messages or iMessages to others users
- [x] Dashboard UI for easy access to Messages / Phone Calling
- [x] Figure out whether or not accessing message and calling history is possible ... and it isn't
- [x] Add Spotify to the dashboard
- [x] Iterate on user interface prototypes (what happens when there are no calendar events?) 
- [x] Retrieving contact information from calendar events (limited)
- [ ] [in progress] Compute ETA given current location & destination
- [ ] [in progress] Use origami to design the user interface
- [ ] [in progress] Draw route on the map using Google Maps Directions API
- [ ] Need to parse JSON in a clean way: cleanly parse using built-in library, or import some third-party library (SwiftyJSON)
- [ ] Implement smart filtering of contacts (back end)
- [ ] Implement smart filtering of contacts (front end - user interface)

