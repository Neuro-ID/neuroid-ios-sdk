
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)](https://github.com/Neuro-ID/mobile-sdk-ios/blob/master/LICENSE)

  

# Neuro-ID Mobile SDK for iOS

  

Neuro-ID's Mobile SDK makes it simple to embed behavioral analytics inside your mobile app. With a few lines of code, you can connect your app with the Neuro-ID platform and make informed decisions about your users.

  

## Table of contents

  

-  [Documentation](#documentation-)

-  [Installation](#installation-)

- [Swift Package Manager](#swift-package-manager-)

- [CocoaPods](#cocoapods-)

  

-  [Getting started](#getting-started-)

  

-  [Sample application](#sample-application-)

-  [License](#license-)

  

### Documentation [⤴](#table-of-contents)

  

## Installation [⤴](#table-of-contents)

  

<a href="https://github.com/Neuro-ID/mobile-sdk-ios/releases/latest">Download the latest version</a>

  

### Swift Package Manager [⤴](#table-of-contents)

  

### CocoaPods [⤴](#table-of-contents)

  

## Getting Started [⤴](#table-of-contents)
### 1. Setup your API key
- Add the code below to your `application(:didFinishLaunchingWithOptions:)`

  `NeuroID.configure(clientKey: "provided_api_key", userId: "user_id_in_your_system_id")`

- To have th best results, you have to set the id for every UIView you want to track.

```Swift
hotelNameTextField.id = "hotelNameTextField"
```


### 2. Silently logging
Neuro-ID SDK silently logs your behaviors. We silently capture the events below: 
- UIViewController life cycle: `viewDidLoad` `viewWillAppear`, `viewWillDisappear`
- UITextField, UITextView notification: `textDidBeginEditingNotification`, `textDidChangeNotification`, `textDidEndEditingNotification`.
- UIControl touch events: `touchDown`, `touchUpInside`, `touchUpOutside`

You can manually track above events by the following functions directly in your `UIViewController`: 
- log(event: NIEvent)
- log(eventName: NIEventName) 
- logViewWillAppear(params: [String: Any?])
- logViewDidLoad(params: [String: Any?])
- logViewWillDisappear(params: [String: Any?])

### 3. Manually logging
We provide some functions to help you log your actions easily via `NeuroIDTracker`
- logCheckBoxChange
- logRadioChange
- logSubmission
- logSubmissionSuccess
- logSubmissionFailure
  
### 4. NIEvent
NIEvent can be initialized with predefined `NIEventName` (link to the file on github) but you definitely can add your custom event. 

## Sample application [⤴](#table-of-contents)

  

## Help [⤴](#table-of-contents)

  

For help with the Neuro-ID Mobile SDK, see the [latest documentation]() or join the conversation in our [slack channel]().

  

## License [⤴](#table-of-contents)

  

The Neuro-ID Mobile SDK is provided under an [MIT License](LICENSE).
