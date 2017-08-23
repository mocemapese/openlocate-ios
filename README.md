
![OpenLocate](http://imageshack.com/a/img922/4800/Pihgqn.png)

# OpenLocate

OpenLocate is an open source Android and iOS SDK for mobile location collection.

## Purpose

### Why is this project useful?

OpenLocate is supported by developers, non-profits, trade groups, and industry for the following reasons:

* Collecting location data in a battery efficient manner that does not adversely affect mobile application performance is non-trivial. OpenLocate enables everyone in the community to benefit from shared knowledge around how to do this well.
* Creates standards and best practices for location collection.
* Developers have full transparency on how OpenLocate location collection works.
* Location data collected via OpenLocate is solely controlled by the developer.

### What can I do with location data?

Mobile application developers can use location data collected via OpenLocate to:

* Enhance their mobile application using context about the user’s location.
* Receive data about the Points of Interest a device has visited by enabling integrations with 3rd party APIs such as Google Places or Foursquare Venues
* Send location data to partners of OpenLocate via integrations listed here.

### Who is supporting OpenLocate?

OpenLocate is supported by mobile app developers, non-profit trade groups, academia, and leading companies across GIS, logistics, marketing, and more.

## Requirements
- iOS 10

## Installation

1. Cocoapods

If you use cocoapods, add the following line in your podfile and run `pod install`

```ruby
pod 'OpenLocate'
```

## Usage

### Start tracking of location

1. Add `NSLocationAlwaysAndWhenInUseUsageDescription` in the `info.plist` of your application

```xml
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This application would like to access your location.</string>
```

Build your configuration with your URL and headers and supply it to the `startTracking` method.

```swift
guard let uuid = UUID(uuidString: "<YOUR_UUID>") else {
  print("Invalid UUID")
  return
}
let configuration = SafeGraphConfiguration(uuid: uuid, token: "<YOUR_TOKEN>")

do {
  try OpenLocate.shared.startTracking(with: configuration)
} catch {
  print("Could not start tracking")
}
```


### Stop tracking of location

To stop the tracking call `stopTracking` method on the `OpenLocate`. Get the instance by calling `shared`.

```swift
OpenLocate.shared.stopTracking()
```


### Fields collected by the SDK

The following fields are collected by the SDK to be sent to a private or public API:

1. `latitude` - Latitude of the device
2. `longitude` - Longitude of the device
3. `utc_timestamp` - Timestamp of the recorded location in epoch
4. `horizontal_accuracy` - The accuracy of the location being recorded
5. `id_type` - 'aaid' for identifying android advertising type
6. `ad_id` - Advertising identifier
7. `ad_opt_out` - Limited ad tracking enabled flag

## Communication

- If you **need help**, use [Stack Overflow](https://stackoverflow.com). (Tag 'OpenLocate') 
- If you **found a bug**, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.

## License

This project is licensed under the MIT License - see the LICENSE.md file for details.