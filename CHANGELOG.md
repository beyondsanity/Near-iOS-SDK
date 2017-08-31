2.2 Release notes (2017-08-31)
=============================================================

### API Breaking Changes

* Changed Near manager "sendTracking" method.

### Enhancements

* Better responsiveness.

### Bugfixes

* None.

1.0.8 Release notes (2017-08-02)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* None.

### Bugfixes

* Fixes an issue for deferred user data.

1.0.7 Release notes (2017-08-02)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* None.

### Bugfixes

* Fixes an issue with beacon monitoring.

1.0.6 Release notes (2017-07-31)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* None.

### Bugfixes

* Fixes set single user data.

1.0.5 Release notes (2017-07-28)
=============================================================

### API Breaking Changes

* Local notifications are now handled like a remote notification, "handleLocal..." methods are removed, use "processRecipe" with userInfo instead.

### Enhancements

* None.

### Bugfixes

* Fixes a crash when the api key is invalid or malformed.

1.0.4 Release notes (2017-07-26)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* None.

### Bugfixes

* Fixes "Reachability" code collision.

1.0.3 Release notes (2017-07-24)
=============================================================

### API Breaking Changes

* The Near Manager is now singleton, there are no more "initWithApiKey" and "init(apiKey)" methods.

### Enhancements

* None.

### Bugfixes

* Fixes some cases for region monitoring.

1.0.2 Release notes (2017-07-18)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* None.

### Bugfixes

* Fixes a case where beacon has proximity value unknown.
* Fixes a gefeonce/monitoring case.

1.0.1 Release notes (2017-07-13)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* Reset profile creates a new profile.

### Bugfixes

* None.

1.0.0 Release notes (2017-07-13)
=============================================================

### API Breaking Changes

* "recipes" method on Near Manager is no more available, use recipes download with callback instead.

### Enhancements

* New recipes download method.

### Bugfixes

* Fixes cache loading in RecipesManager.

0.9.41 Release notes (2017-07-12)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* Geotags support.
* Backoff system for user's data.

### Bugfixes

* None.

0.9.40 Release notes (2017-07-11)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* None.

### Bugfixes

* Fixes NITManagerDelegate call.

0.9.39 Release notes (2017-07-07)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* None.

### Bugfixes

* Includes NITSimpleNotification type for Objective-C.

0.9.38 Release notes (2017-07-06)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* None.

### Bugfixes

* Fixes a problem with the SDK installation process.

0.9.37 Release notes (2017-07-05)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* None.

### Bugfixes

* Fixes wrapper for Swift: support for "showBackgroundNotification".

0.9.36 Release notes (2017-07-05)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* None.

### Bugfixes

* Fixes a crash due to "installationId" missing.
* Fixes cooldown for automatic background notification.

0.9.35 Release notes (2017-06-30)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* Push notifications can now be handled without network request.

### Bugfixes

* None.

0.9.34 Release notes (2017-06-27)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* None.

### Bugfixes

* Fixes a lack of icon for coupons.

0.9.33 Release notes (2017-06-22)
=============================================================

### API Breaking Changes

* processRecipes methods return a BOOL.

### Enhancements

* Now by default the SDK gives local background notification for triggers events.
* The processRecipes... methods return a BOOL which means if a remote notification comes from Near or not.

### Bugfixes

* None.

0.9.32 Release notes (2017-06-21)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* None.

### Bugfixes

* Crash fix for iOS 9.

0.9.31 Release notes (2017-06-20)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* Better location accuracy.

### Bugfixes

* None.

0.9.30 Release notes (2017-06-19)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* None.

### Bugfixes

* Fixes date band and days validation with different timezones.

0.9.29 Release notes (2017-06-16)
=============================================================

### API Breaking Changes

* "processRecipeWithUserInfo:" becomes "processRecipeSimpleWithUserInfo:" in obj-c, in swift is "processRecipeSimple".

### Enhancements

* None.

### Bugfixes

* Fixes time band validation with different timezones.
* Fixes a swift call to the obj-c "processRecipe" method

0.9.28 Release notes (2017-06-14)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* None.

### Bugfixes

* Fixes datetime for trackings.

0.9.27 Release notes (2017-06-13)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* None.

### Bugfixes

* Fixes scheduling validation for recipe.

0.9.26 Release notes (2017-06-12)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* Support for iOS Notification Service Extension.

### Bugfixes

* None.

0.9.25 Release notes (2017-06-07)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* User data point can receive a nil value.

### Bugfixes

* Fixes push recipe notification state (engaged).

0.9.24 Release notes (2017-06-05)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* None.

### Bugfixes

* Manager "Send event" callback is now received on the main thread.

0.9.23 Release notes (2017-05-29)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* Removed tracking event check, you can now send custom tracking event.

### Bugfixes

* None.

0.9.22 Release notes (2017-05-29)
=============================================================

### API Breaking Changes

* NITManager setDeviceToken: changed in setDeviceTokenWithData:.

### Enhancements

* Added "url" method for NITImage type.

### Bugfixes

* None.

0.9.21 Release notes (2017-05-23)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* None.

### Bugfixes

* Fixes an issue with the bluetooth state change.
* Fixes a node management issue.

0.9.20 Release notes (2017-05-22)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* None.

### Bugfixes

* Fixes recipe scheduling with days.

0.9.19 Release notes (2017-05-19)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* "recipeId" field for coupon claim.

### Bugfixes

* None.

0.9.18 Release notes (2017-05-17)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* You can process a recipe from a push and have the response in the completion block (processRecipeWithUserInfo:completion:).

### Bugfixes

* None.

0.9.17 Release notes (2017-05-16)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* None.

### Bugfixes

* Fix for unvisited nodes.

0.9.16 Release notes (2017-05-16)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* Now if you are inside a geofences for the first time the sdk acts like it's a geofence enter, so it gives you a content if available.

### Bugfixes

* None.

0.9.15 Release notes (2017-05-12)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* None.

### Bugfixes

* Bug fix for the location timer in Geopolis.

0.9.14 Release notes (2017-05-10)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* None.

### Bugfixes

* Various locations fixes.

0.9.13 Release notes (2017-05-09)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* None.

### Bugfixes

* Coupons request fix, profileId was missing.
* "title" for SimpleNotification now isn't mandatory.

0.9.12 Release notes (2017-05-08)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* More logs available for analysis.
* Added "redeemable" date for coupons

### Bugfixes

* "expires" date fix in NITCoupon.
* Fix for feedback reaction cache.

0.9.11 Release notes (2017-05-02)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* Geopolis region trigger improvements.

### Bugfixes

* None.

0.9.10 Release notes (2017-04-28)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* Removed message "Turn on Bluetooth to allow app to connect to accessories".

### Bugfixes

* None.

0.9.9 Release notes (2017-04-28)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* Thread safety and performance improvements for trackings manager.
* Removed "Reachability" logs.

### Bugfixes

* None.

0.9.8 Release notes (2017-04-27)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* None.

### Bugfixes

* Fix an important issue where you could have sevaral different profiles for the same device.
* Fix an issue about too many trackings logs.
* Fixes push notification tracking (notified, engaged).

0.9.7 Release notes (2017-04-27)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* The SDK trackings now have a retry system.

### Bugfixes

* Fix an issue for manager delegate where it was on a background thread, therefore the UI was locked.

0.9.6 Release notes (2017-04-21)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* None.

### Bugfixes

* Fix an issue for Geofence events: the SDK couldn't dispatch events.

0.9.5 Release notes (2017-04-20)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* Enable/Disable logging method (NITLog).

### Bugfixes

* Fix an issue for beacons ranging where you could have several notifications for the same beacon.

0.9.4 Release notes (2017-04-19)
=============================================================

### API Breaking Changes

* None.

### Enhancements

* Trigger log available for Geopolis: you can find a useful log in the console starting with "triggerWithEvent".

### Bugfixes

* Fix an issue for Geopolis event trackings, now the NearIT services have the right trackings.
* Fixed installation sdk_version.

0.9.3 Release notes (2017-04-18)
=============================================================

New NearITSDKSwift pod (CocoaPods).

### API Breaking Changes

* None.

### Enhancements

* None.

### Bugfixes

* None.
