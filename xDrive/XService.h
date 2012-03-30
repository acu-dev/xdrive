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
@class DirectoryContentsViewController;
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

/**
 File system path to the directory that server specific files should be stored.
 */
@property (nonatomic, strong, readonly) NSString *documentsPath;

/**
 File system path to the directory that server specific cache files should be stored.
 */
@property (nonatomic, strong, readonly) NSString *cachesPath;

///---------------------
/// @name Initialization
///---------------------

/**
 Designated initializer and getter.
 
 @discussion One XService to rule them all. Ensures that only one instance of itself is instantiated.
 */
+ (XService *)sharedXService;

///------------------------
/// @name Directory Updates
///------------------------

- (void)updateDirectory:(XDirectory *)directory forContentsViewController:(DirectoryContentsViewController *)viewController;
- (void)receivedDirectoryDetails:(NSDictionary *)details;
- (void)didFinishUpdatingDirectoryAtPath:(NSString *)path;
- (void)updateDirectoryAtPath:(NSString *)path failedWithError:(NSError *)error;



///--------------
/// @name Caching
///--------------

/**
 Completely removes all cached files.
 
 @param completionBlock Block to be executed upon completion.
 */
- (void)clearCacheWithCompletionBlock:(void (^)(NSError *error))completionBlock;

/**
 Moves a file to it's proper cache location and updates local storage status.
 
 @discussion Used for moving downloaded files from a temp directory to the proper cache path.
 
 @param file File object to have file cached for.
 @param tmpPath Path to file location that needs to be cached.
 */
- (void)cacheFile:(XFile *)file fromTmpPath:(NSString *)tmpPath;

/**
 Clears cache for the specified entry. If entry is a file and has been cached, cached file will be removed. If entry is a directory, any contents are recursively cleared of their cached files.
 
 @discussion Used to ensure all cached files are cleared from a specified path, wether it's a single file or directory.
 
 @param entry The entry object to have it's cache cleared.
 */
- (void)removeCacheForEntry:(XEntry *)entry;

/**
 Removes a cached file and updates local storage status.
 
 @param file File object to have cached file removed.
 */
- (void)removeCacheForFile:(XFile *)file;

/*
 Recursively searches directory contents for cached files and removes them.
 
 @param directory Directory object to have all cached files cleared from.
 */
- (void)removeCacheForDirectory:(XDirectory *)directory;

/*
 Removes the oldest cached files until total cache size is less than specified amount.
 
 @discussion Used when decreasing local storage amount and when making space to cache new files.
 
 @param bytes Size to make the total cache size less than.
 */
- (void)removeOldCacheUntilTotalCacheIsLessThanBytes:(long long)bytes;

///------------
/// @name Files
///------------

- (void)downloadFile:(XFile *)file withDelegate:(id<XServiceRemoteDelegate>)delegate;
// Downloads a file to a temp location and notifies the delegate.

- (void)moveFileAtPath:(NSString *)oldFilePath toPath:(NSString *)newFilePath;
// Moves a file from one location to another



///------------
/// @name Utils
///------------

/**
 Gets the appropriate icon name for the specified entry's mime-type.
 
 @param entryType The entry object's mime-type.
 
 @return The image name to use for an icon.
 */
- (NSString *)iconNameForEntryType:(NSString *)entryType;


@end




















