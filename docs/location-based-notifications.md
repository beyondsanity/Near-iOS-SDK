# Location Based Notifications

When you want to start the radar for **geofences and beacons** call this method:

```swift
// Swift
// call this when you are given the proper permission for scanning (.Always or .InUse)
manager.start()
// to stop the radar call the method manager.stop()
```

```objective-c
// Objective-C
// call this when you are given the proper permission for scanning (.Always or .InUse)
[manager start];
// to stop the radar call the method [manager stop];
```

You must add the `NSLocationAlwaysUsageDescription` or `NSLocationWhenInUseUsageDescription` in the project Info.plist


To learn how to deal with in-app content see this [section](handle-content.md).
