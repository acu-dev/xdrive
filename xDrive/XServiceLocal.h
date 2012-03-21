//
//  XServiceLocal.h
//  xDrive
//
//  Created by Chris Gibbs on 7/5/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

#import "XFile.h"
#import "XDirectory.h"
#import "XDefaultPath.h"

@interface XServiceLocal : NSObject

@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;

///--------------------
/// @name Remote Server
///--------------------

/**
 The server object containing url and service information.
 */
//@property (nonatomic, strong, readonly) XServer *server;

///---------------------
/// @name Initialization
///---------------------

/**
 Creates and initializes an `XServiceLocal` object with a main managed object context. Sets up the persistent store coordinator and creates the main queue's managed object context used by fetched results controllers.
 
 @discussion This should only be called once by XService. Provides the context used by fetched results controllers so changes made with this object should be short and sweet, so as not to block the UI. For heavy lifting, use a different `XServiceLocal` object created from `newServiceForOperation`.
 
 @return The newly-initialized service
 */
- (id)init;

- (XServer *)server;

/**
 Creates and initializes an `XServiceLocal` object with a private managed object context as a child of the receiver's managed object context.
  
 @discussion Use this to create instances of the local service that need their own context (i.e. background operations).
 
 @return The newly-initialized service
 */
- (XServiceLocal *)newServiceForOperation;

///-------------
/// @name Saving
///-------------

/**
 Saves the local and parent (if set) managed object contexts.
 
 @param completion The block to be called when the context completes the save
 */
- (void)saveWithCompletionBlock:(void (^)(NSError *error))completionBlock;

///-------------------------------
/// @name Getting/Creating Entries
///-------------------------------

/**
 Creates a new server object in the local context but does not save. This should only ever be called during the inital setup process.
 
 @discussion The context is not saved, it is up to the sender to call `saveWithCompletionBlock:`.
 
 @param protocol Either http or https
 @param port Port the service is running on
 @param hostname Server's hostname
 @param context Webapp's context root
 @param servicePath Service base path
 
 @return The newly-created server object
 */
- (XServer *)createServerWithProtocol:(NSString *)protocol port:(NSNumber *)port hostname:(NSString *)hostname
							  context:(NSString *)context servicePath:(NSString *)servicePath;

/**
 Creates a new default path object at the specified path.
 
 @discussion The context is not saved, it is up to the sender to call `saveWithCompletionBlock:`.
 
 @return The newly-created default path object
 */
- (XDefaultPath *)createDefaultPathAtPath:(NSString *)path withName:(NSString *)name;

/**
 Gets a file object at the specified path. If the file object does not exist locally, it is created.
 
 @param path The file's path on the remote file system.
 
 @discussion The context is not saved, it is up to the sender to call `saveWithCompletionBlock:`.
 
 @return The file object at the specified path
 */
- (XFile *)fileWithPath:(NSString *)path;

/**
 Gets a directory object at the specified path. If the directory object does not exist locally, it is created.
 
 @param path The directory's path on the remote file system.
 
 @discussion The context is not saved, it is up to the sender to call `saveWithCompletionBlock:`.
 
 @return The directory object at the specified path
 */
- (XDirectory *)directoryWithPath:(NSString *)path;

///-----------------------
/// @name Removing Entries
///-----------------------

/**
 Deletes a specified entry from the context. If entry is a directory, any contents will be deleted as well.
 
 @discussion The context is not saved, it is up to the sender to call `saveWithCompletionBlock:`.
 
 @param entry The entry object to be removed from the store.
 */
- (void)removeEntry:(XEntry *)entry;

///-----------------------------------
/// @name Getting a Results Controller
///-----------------------------------

/**
 Creates a results controller for the contents of a specified directory.
 
 @param directory The directory object whose contents need to be controlled.
 
 @return The newly-created fetched results controller
 */
- (NSFetchedResultsController *)contentsControllerForDirectory:(XDirectory *)directory;

/**
 Creates a results controller for the most recenctly accessed files.
 
 @return The newly-created fetched results controller
 */
- (NSFetchedResultsController *)recentlyAccessedFilesController;

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
