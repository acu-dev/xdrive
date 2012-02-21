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
@protocol XServiceRemoteDelegate;



@interface XService : NSObject

@property (nonatomic, strong, readonly) XServiceLocal *localService;
	// A service object to handle reading/writing objects to local db

@property (nonatomic, strong, readonly) XServiceRemote *remoteService;
	// A service object to handle fetching/pushing data to the server


/* Init */

+ (XService *)sharedXService;
	// One XService to rule them all


/* Accessors */

- (XServer *)activeServer;
	// Accessor for the server object saved in db (nil if none saved)

- (NSString *)documentsPath;
	// Path for database and metadata files to be stored

- (NSString *)cachesPath;
	// Path for files to be cached


/* Directories */

- (XDirectory *)directoryWithPath:(NSString *)path;
	// Gets a directory object at given path. Fires off remote fetch in background
	// and if necessary, directory contents are updated.

- (XDirectory *)updateDirectoryDetails:(NSDictionary *)details;
	// Updates directory contents with the passed details (Usually from the server).


/* Files */

- (void)downloadFile:(XFile *)file withDelegate:(id<XServiceRemoteDelegate>)delegate;
	// Downloads a file to a temp location and notifies the delegate.


/* Cache */

- (void)clearCache;
	// Removes all cached content

- (void)removeCacheForDirectory:(XDirectory *)directory;
	// Recursively searches directory contents for cached files to remove

- (void)cacheFile:(XFile *)file fromTmpPath:(NSString *)tmpPath;
	// Moves a downloaded file to it's cache location and updates local storage status

- (void)removeCacheForFile:(XFile *)file;
	// Removes a cached file and updates local storage status


@end




















