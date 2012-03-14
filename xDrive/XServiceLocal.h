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
 The server object containing url and service information.
 */
@property (nonatomic, strong, readonly) XServer *server;

///---------------------
/// @name Initialization
///---------------------

/**
 Designated initializer. Sets up the persistent store coordinator and creates the main queue's managed object context used by fetched results controllers.
 
 @discussion This should only be called once by XService. Changes made with this object should be short and sweet, so as not to block the UI.
 */
- (id)init;

/**
 Creates a new instance of XServiceLocal with a new private managed object context as a child of the receiver's managed object context.
  
 @discussion Use this to create instances of the local service that need their own context (i.e. background operations).
 */
- (XServiceLocal *)newServiceForOperation;

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
