![OpenLocate](http://imageshack.com/a/img922/4800/Pihgqn.png)


OpenLocate is an open source location tracking SDK built for android and iOS platforms.  

- [Features](#features)
- [Requirements](#requirements)
- [Communication](#communication)
- [Installation](#installation)
- [Usage](#usage)
- [FAQ](#faq)
- [Credits](#credits)
- [License](#license)

## Features

- [x] Optimized to reduce battery consumption
- [ ] Elegant request queueing
- [ ] Offline first - local caching, send to server as per defined network reporting frequency 
- [ ] Customizable local location recording frequency
- [ ] Customizable network reporting frequency
- [ ] Control required accuracy for recorded locations
- [ ] Define your own backend links where locations will be reported
- [ ] Offline mode - for network failures, etc
- [ ] Nearby places
- [ ] Compress (Gzip) payload


## Requirements

- iOS 10

## Communication

- If you **need help**, use [Stack Overflow](https://stackoverflow.com). (Tag 'OpenLocate') 
- If you **found a bug**, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.

## Installation

1. Cocoapods

If you use cocoapods, add the following line in your podfile and run `pod install`

```ruby
pod 'OpenLocate'
```

## Usage

### Start tracking of location

1. Add `NSLocationWhenInUseUsageDescription` in the `info.plist` of your application

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This application would like to access your location.</string>
```

2. Start location tracking by providing your configuration as a object which conforms to `Configuration` protocol. The `Configuration` protocol should return `url` as `String` and optionally `headers` as `[String: String]`. To send location to SafeGraph servers, use `SafeGraphConfiguration`, which also conforms to `Configuration`, class as mentioned below.

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

Following fields are collected by the SDK for the ingestion API

1. `latitude` - Latitude of the device
2. `longitude` - Longitude of the device
3. `utc_timestamp` - Timestamp of the recorded location in epoch
4. `horizontal_accuracy` - The accuracy of the location being recorded
5. `id_type` - 'aaid' for identifying android advertising type
6. `ad_id` - Advertising identifier
7. `ad_opt_out` - Limited ad tracking enabled flag

## FAQ

@todo

## Credits

@todo

## License

MIT License

Copyright (c) 2017 OpenLocate

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.