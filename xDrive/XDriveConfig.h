//
//  XDriveConfig.h
//  xDrive
//
//  Created by Chris Gibbs on 9/16/11.
//  Copyright (c) 2011 Abilene Christian University. All rights reserved.
//

#import "XServer.h"



// Default server connection info
static int defaultServerPort = 443;
static NSString *defaultServerProtocol = @"https";
static NSString *defaultServiceBasepath = @"/xservice/rs";
#pragma unused(defaultServerPort)


// Be sure to turn off all logging before a release build!

#define XDRV_LOG
	// If defined, will log ERROR & WARNING type messages to the console.
	// Watch for these logs during development.

//#define XDRV_DEBUG
	// If defined, will log INFO & DEBUG type messages to the console.
	// Useful in examining data as it moves around.








@interface XDriveConfig : NSObject

/* App Info */

+ (NSString *)appVersion;
	// Current version of the app as defined in the Info plist

+ (NSString *)appName;
	// Display name of the app as defined in the Info plist

+ (NSArray *)supportedServiceVersions;
	// List of xservice versions supported by this version of xdrive

/* Settings */

+ (NSDictionary *)localStorageOption;
+ (void)setLocalStorageOption:(NSDictionary *)option;
	// Get/set settings for local storage

+ (NSArray *)localStorageOptions;
	// All possible settings for local storage

+ (NSDictionary *)defaultLocalStorageOption;
	// Default local storage settings

+ (long long)totalCachedBytes;
+ (void)setTotalCachedBytes:(long long)cachedBytes;
	// Get/set number of bytes cached locally


/* Tab Items */

+ (void)saveTabItemOrder:(NSArray *)order;
	// Writes the tab item order to the user preferences

+ (NSArray *)getSavedTabItemOrder;
	// Retrieves the tab item order from user preferences. Returns nil of none saved

/* Utils */

+ (NSURLProtectionSpace *)protectionSpaceForServer:(XServer *)server;
	// Util method to generate a protection space

@end









//
// Log Macro
//
#ifdef XDRV_LOG
#	define XDrvLog(fmt, ...) NSLog((@"%s " fmt), __PRETTY_FUNCTION__, ##__VA_ARGS__);
#else
#	define XDrvLog(...)
#endif

//
// Debug Macro
//
#ifdef XDRV_DEBUG
#	define XDrvDebug(fmt, ...) NSLog((@"%s " fmt), __PRETTY_FUNCTION__, ##__VA_ARGS__);
#else
#	define XDrvDebug(...)
#endif