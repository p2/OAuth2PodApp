OAuth2 iOS Test App
===================

This is an [OAuth2 framework][oauth2] sample app running on iPhone.
It uses [Cocoapods][] to install the framework, currently version 2.1.
There also is an [OS X Test App][osx] that does not use CocoaPods.

This example app has you log in to GitHub and then fetches your username and avatar.

> **Note** that there is a "forget tokens" button, which will throw away your current access token, but it will NOT destroy your session with GitHub, so subsequent taps on "Sign In" will briefly show GitHub's login screen which will log you in automatically and disappear immediately.
> If you use native login (i.e. Safari), you can visit GitHub in Safari and log out there.


### Embedded vs. Native

There are two buttons, one to login using a built-in web view controller and one to open Safari for login.
This is achieved by setting `oauth2.authConfig.authorizeEmbedded` to either _true_ or _false_.


### Installation

Refer to the [Cocoapods installation guide][cocinstall] if you don't yet have it.
Then:

```bash
git clone https://github.com/p2/OAuth2PodApp.git
cd OAuth2PodApp
pod install
```

Now you can open `OAuth2PodApp.xcworkspace` (**not** the _xcodeproj_ file) and **hit Run**.


License
=======

[![CC0](http://i.creativecommons.org/p/zero/1.0/88x31.png)][cc0]

<a rel="dct:publisher" href="https://github.com/p2/OAuth2PodApp">I have waived</a> all copyright and related or neighboring rights to <span property="dct:title">OAuth2PodApp</span>.

[oauth2]: https://github.com/p2/OAuth2
[cocoapods]: https://cocoapods.org/pods/p2.OAuth2
[cocinstall]: https://guides.cocoapods.org/using/getting-started.html
[osx]: https://github.com/p2/OAuth2App
[cc0]: http://creativecommons.org/publicdomain/zero/1.0/
