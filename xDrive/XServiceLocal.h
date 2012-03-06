//
//  XServiceLocal.h
//  xDrive
//
//  Created by Chris Gibbs on 7/5/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

#import "XFile.h"
#import "XDirectory.h"

@interface XServiceLocal : NSObject

///--------------------
/// @name Remote Server
///--------------------

/**
 The persistent store coordinator used by the main managed object context. Use this for creating temporary managed object contexts.
 */
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

/**
 The server object containing url and service information.
 */
@property (nonatomic, strong, readonly) XServer *server;

///----------------------
/// @name Getting Entries
///----------------------

/**
 Gets a file object at the specified path.
 
 @param path The file's path on the remote file system.
 
 @discussion If the file object does not exist locally, it is created.
 */
- (XFile *)fileWithPath:(NSString *)path;

/**
 Gets a directory object at the specified path.
 
 @param path The directory's path on the remote file system.
 
 @discussion If the directory object does not exist locally, it is created.
 */
- (XDirectory *)directoryWithPath:(NSString *)path;

///-----------------------
/// @name Updating Entries
///-----------------------



///-----------------------------------
/// @name Getting a Results Controller
///-----------------------------------

/**
 Gets a contents controller for a specified directory.
 
 @param directory The directory object whose contents need to be controlled.
 */
- (NSFetchedResultsController *)contentsControllerForDirectory:(XDirectory *)directory;

///---------------------------
/// @name Getting Recent Files
///---------------------------

/**
 Gets a list of cached files ordered by their lastAccess date.
 
 @param ascending Determines if the results are returned in ascending order (oldest lastAccess first).
 
 @discussion Useful for removing old cached files to make room for new ones.
 */
- (NSArray *)cachedFilesOrderedByLastAccessAscending:(BOOL)ascending;

///------------
/// @name Reset
///------------

/**
 Resets the database to an empty state.
 
 @discussion Completely deletes the database and re-creates it. Use only when no actions are being performed.
 */
- (void)resetPersistentStore;

@end
