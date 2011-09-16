//
//  XDriveConfig.h
//  xDrive
//
//  Created by Chris Gibbs on 9/16/11.
//  Copyright (c) 2011 Abilene Christian University. All rights reserved.
//


// Be sure to turn off all logging before a release build!

#define XDRV_LOG
	// If defined, will log ERROR & WARNING type messages to the console.
	// Watch for these logs during development.

#define XDRV_DEBUG
	// If defined, will log INFO & DEBUG type messages to the console.
	// Useful in examining data as it moves around.

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