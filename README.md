xDrive
======

xDrive is an iOS app for accessing files stored in a Blackboard Xythos files system. Browsed files and directories are stored locally allowing the user to maintain a cache of files on their device that can be viewed/used even in offline mode.

xDrive requires the Xythos server to be running [xService](https://github.com/acu-dev/xservice) (the server-side services for xDrive to communicate with). Default browsing paths (e.g. Home, Departments, etc.) are configured in xService and downloaded to the app upon login.

Only [file types supported by UIWebView](https://developer.apple.com/library/ios/#qa/qa1630/_index.html#//apple_ref/doc/uid/DTS40008749) are supported for in-app viewing.