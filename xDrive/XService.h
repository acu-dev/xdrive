//
//  XService.h
//  xDrive
//
//  Created by Chris Gibbs on 7/1/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

#import "XServiceLocal.h"
#import "XServiceRemote.h"
#import "XServer.h"
#import "DirectoryContentsViewController.h"
@protocol XServiceRemoteDelegate;



@interface XService : NSObject

///---------------
/// @name Services
///---------------

/**
 The service object that handles local database operations.
 */
@property (nonatomic, strong, readonly) XServiceLocal *localService;

/**
 The service object that handles communication with the server.
 */
@property (nonatomic, strong, readonly) XServiceRemote *remoteService;

///---------------------
/// @name Initialization
///---------------------

/**
 Designated initializer and getter.
 
 @discussion One XService to rule them all. Ensures that only one instance of itself is instantiated.
 */
+ (XService *)sharedXService;

///----------------
/// @name Accessors
///----------------

/**
 The file system path for the server specific documents directory. Used for storing database and metadata files.
 */
- (NSString *)documentsPath;

/**
 The file system path for the server specific caches directory. Used for storing cached files.
 */
- (NSString *)cachesPath;

///------------------------
/// @name Directory Actions
///------------------------

- (void)updateDirectory:(XDirectory *)directory withDetails:(NSDictionary *)details;









- (XDirectory *)directoryWithPath:(NSString *)path;
	// Gets a directory object at given path. Fires off remote fetch in background
	// and if necessary, directory contents are updated.

- (XDirectory *)updateDirectoryDetails:(NSDictionary *)details;
	// Updates directory contents with the passed details (Usually from the server).


/* Files */

- (void)downloadFile:(XFile *)file withDelegate:(id<XServiceRemoteDelegate>)delegate;
	// Downloads a file to a temp location and notifies the delegate.

- (void)moveFileAtPath:(NSString *)oldFilePath toPath:(NSString *)newFilePath;
	// Moves a file from one location to another


/* Cache */

- (void)clearCacheWithCompletionBlock:(void (^)(NSError *error))completionBlock;
	// Removes all cached content and calls completion block when done.

- (void)cacheFile:(XFile *)file fromTmpPath:(NSString *)tmpPath;
	// Moves a downloaded file to it's cache location and updates local storage status

- (void)removeCacheForFile:(XFile *)file;
	// Removes a cached file and updates local storage status

- (void)removeCacheForDirectory:(XDirectory *)directory;
	// Recursively searches directory contents for cached files to remove

- (void)removeOldCacheUntilTotalCacheIsLessThanBytes:(long long)bytes;
	// Deletes files until total cache is less than bytes


@end




















