# Guide - Integration with Places API

This guide will help you in integrating `OpenLocate` SDK with your places API.

## Purpose

### Who is this guide for?

This guide is for anyone who wants to use current location of the user to show him nearby places through an API. 


## Usage

1. Add `NSLocationAlwaysAndWhenInUseUsageDescription` in the `info.plist` of your application

```xml
<key>NSLocationAlwaysUsageDescription</key>
<string>This application would like to access your location.</string>
```

Adding this to your application will give a pop to the user which says that the app will use location.


2. Get current location from OpenLocate SDK

To intregate `OpenLocate` with your places API, call the `fetchCurrentLocation` of `OpenLocate` shared instance. This will give you back a `OpenLocateLocation` object if the location was fetched successfully or it will give you an `Error` object.

The `OpenLocateLocation` object has properties like `latitude`, `longitude`, `horizontalAccuracy`, `advertisingId`, `advertisingIdType`, etc.

```swift
try OpenLocate.shared.fetchCurrentLocation { location, error in
  if let location = location {
    fetchNearbyPlaces(location: location)
  } else {
    debugPrint(error.localizedDescription)
  }
}
```

3. Use the `OpenLocateLocation` object in the API call

User the `location` object received in the `fetchCurrentLocation` in your places API.

```swift
func fetchNearbyPlaces(location: OpenLocateLocation, completion: @escaping SafePlacesCompletionHandler) {

  Alamofire.request(
    "https://api.safegraph.com/places/v1/nearby",
    parameters: [
      "advertising_id": location.advertisingId,
      "advertising_id_type": location.advertisingIdType,
      "latitude": location.latitude,
      "longitude": location.longitude,
      "horizontal_accuracy": location.horizontalAccuracy
    ],
    headers: ["Authorization": "Bearer <YOUR_TOKEN>"]
  )
    .responseJSON { response in
      guard let json = response.result.value as? [String: Any],
        let placesJson = json["places"] as? [Any], !placesJson.isEmpty else {
          completion(nil, SafeGraphError.placesNotFound)
          return
        }

        var places = [SafeGraphPlace]()
        for placeJson in placesJson {
          let place = (placeJson as? [String: Any])!
          places.append(SafeGraphPlace(json: place))
        }

        completion(places, nil)
    }
}
```