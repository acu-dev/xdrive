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

@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

// Server
- (XServer *)activeServer;

// Get/create entries
- (XFile *)fileWithPath:(NSString *)path;
- (XDirectory *)directoryWithPath:(NSString *)path;

// Recent files
- (NSArray *)cachedFilesOrderedByLastAccessAscending:(BOOL)ascending;


//- (NSFetchedResultsController *)fetchedResultsControllerForDirectoryContents:(XDirectory *)directory;





@end
