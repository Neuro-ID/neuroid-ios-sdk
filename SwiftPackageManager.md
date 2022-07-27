# Swift Package Manager for NeuroID

## Requirements

---

- Requires Xcode 12.5 or above
- NeuroID supports instillation through SPM for development of iOS 11 and greater.

## Installation

---

### Installation through Xcode

First add the package to your project by selecting `File` → `Add Packages…`  from the Xcode menu Bar.

In the top right corner, search for the Neuro-ID iOS SDK using the repository URL:

```console
https://github.com/Neuro-ID/neuroid-ios-sdk.git
```

Next, set the **Dependency Rule** to `Branch` and specify the following as the branch:
```console
ENG-2789/swift_package_manager
```

Finally, click `Add Package`, specify your targets, and confirm the package addition.
