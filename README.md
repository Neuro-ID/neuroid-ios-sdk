# Neuro-ID Mobile SDK for iOS

Neuro-ID's Mobile SDK makes it simple to embed behavioral analytics inside your mobile app. With a few lines of code, you can connect your app with the Neuro-ID platform and make informed decisions about your users.

## Table of contents

- [Getting started](#getting-started-)

- [Sample application](#sample-application-)

- [License](#license-)

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

For examples of how to integrate the Neuro-ID SDK and a place to experiment, visit [clone our repo and begin tinkering](https://github.com/Neuro-ID/neuroid-ios-sdk-sandbox)

## Help [⤴](#table-of-contents)

For help with the Neuro-ID Mobile SDK, see the [latest documentation](https://neuro-id.readme.io/docs/overview).

## License [⤴](#table-of-contents)

The Neuro-ID Mobile SDK is provided under an [MIT License](LICENSE).
