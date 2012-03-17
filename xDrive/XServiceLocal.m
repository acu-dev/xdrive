//
//  XServiceLocal.m
//  xDrive
//
//  Created by Chris Gibbs on 7/5/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

#import "XServiceLocal.h"
#import "XDriveConfig.h"
#import "NSString+DTPaths.h"
#import "XService.h"



static NSString *DatabaseFileName = @"XDrive.sqlite";
static NSString *ModelFileName = @"xDrive";


@interface XServiceLocal()
@property (nonatomic, strong) NSPersistentStoreCoordinator *_persistentStoreCoordinator;
@property (nonatomic, strong) NSManagedObjectContext *_managedObjectContext;

- (id)initForOperationWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

// Get/create entries
- (XEntry *)entryOfType:(NSString *)type withPath:(NSString *)path;
- (XEntry *)createEntryOfType:(NSString *)type withPath:(NSString *)path;
@end



@implementation XServiceLocal

// Private
@synthesize _persistentStoreCoordinator;
@synthesize _managedObjectContext;

// Public
@synthesize server = _server;





#pragma mark - Initialization

- (id)init
{
	self = [super init];
	if (!self) return nil;
	
	XDrvDebug(@"Initializing local service");
	
	// Setup the model
	NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"xDrive" withExtension:@"momd"];
	NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	
	// Setup the persistent store (database) coordinator
	NSURL *databaseURL = [NSURL fileURLWithPath:[[NSString documentsPath] stringByAppendingPathComponent:DatabaseFileName]];
	NSError *error = nil;
	_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
	if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
												   configuration:nil
															 URL:databaseURL
														 options:nil
														   error:&error])
	{
		XDrvLog(@"Error: Unable to add persistent store to coordinator: %@", error);
		return nil;
	}
	
	// Create main managed object context
	_managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	[_managedObjectContext setPersistentStoreCoordinator:_persistentStoreCoordinator];
	
    return self;
}

- (id)initForOperationWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    self = [super init];
    if (!self) return nil;
	
	// Set managed object context (See newServiceForOperation)
	_managedObjectContext = managedObjectContext;
	_server = nil;
    
    return self;
}

- (XServiceLocal *)newServiceForOperation
{
	// Create new private managed object context as a child of the receiver's managed object context
	NSManagedObjectContext *privateManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	[privateManagedObjectContext setParentContext:_managedObjectContext];
	
	return [self initForOperationWithManagedObjectContext:privateManagedObjectContext];
}



#pragma mark - Saving

- (void)saveWithCompletionBlock:(void (^)(NSError *error))completionBlock
{
	[_managedObjectContext performBlock:^{
		
		// Save local context
		NSError *error = nil;
		if (![_managedObjectContext save:&error])
		{
			XDrvLog(@"Error saving context: %@", error);
			completionBlock(error);
		}
		else
		{
			if (_managedObjectContext.parentContext)
			{
				[_managedObjectContext.parentContext performBlock:^{
					// Save parent context
					NSError *parentError = nil;
					if (![_managedObjectContext.parentContext save:&parentError])
					{
						XDrvLog(@"Error saving parent context: %@", parentError);
						completionBlock(parentError);
					}
					else
					{
						// Parent context finished saving
						completionBlock(nil);
					}
				}];
			}
			else
			{
				// Local context finished saving
				completionBlock(nil);
			}
		}
	}];
}



#pragma mark - Accessors

- (XServer *)server
{
	if (!_server)
	{
		NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Server"];

		NSError *error = nil;
		NSArray *fetchedObjects = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
		if (![fetchedObjects count])
			return nil;
		_server = [fetchedObjects objectAtIndex:0];
		XDrvLog(@"Fetched server object");
	}
	else
	{
		XDrvLog(@"Returning pre-fetched server object");
	}
	return _server;
}



#pragma mark - Get/create entries

- (XServer *)createServerWithProtocol:(NSString *)protocol port:(NSNumber *)port hostname:(NSString *)hostname
							  context:(NSString *)context servicePath:(NSString *)servicePath
{
	XServer *newServer = [NSEntityDescription insertNewObjectForEntityForName:@"Server" 
											inManagedObjectContext:_managedObjectContext];
	newServer.protocol = protocol;
	newServer.port = port;
	newServer.hostname = hostname;
	newServer.context = context;
	newServer.servicePath = servicePath;
	return newServer;
}

- (XDefaultPath *)createDefaultPathAtPath:(NSString *)path withName:(NSString *)name
{
	XDefaultPath *defaultPath = [NSEntityDescription insertNewObjectForEntityForName:@"DefaultPath"
															  inManagedObjectContext:_managedObjectContext];
	defaultPath.path = path;
	defaultPath.name = name;
	[_server addDefaultPathsObject:defaultPath];
	
	//[self saveWithCompletionBlock:^(NSError *error) {}];
	return defaultPath;
}

- (XFile *)fileWithPath:(NSString *)path
{
	return (XFile *)[self entryOfType:@"File" withPath:path];
}

- (XDirectory *)directoryWithPath:(NSString *)path
{
	return (XDirectory *)[self entryOfType:@"Directory" withPath:path];
}

- (XEntry *)entryOfType:(NSString *)type withPath:(NSString *)path
{
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:type];
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"path == %@", path]];
	[fetchRequest setFetchBatchSize:1];
	
	NSError *error = nil;
	NSArray *fetchedObjects = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
	if (!fetchedObjects)
	{
		// Something went wrong
		XDrvLog(@"Error performing fetch request: %@", [error localizedDescription]);
		return nil;
	}
	
	if (![fetchedObjects count])
	{
		// No entries found, create one
		return [self createEntryOfType:type withPath:path];
	}
	else
	{
		return [fetchedObjects lastObject];
	}
}

- (XEntry *)createEntryOfType:(NSString *)type withPath:(NSString *)path
{
	XEntry *newEntry = [NSEntityDescription insertNewObjectForEntityForName:type
													 inManagedObjectContext:_managedObjectContext];
	newEntry.path = path;
	newEntry.name = [path lastPathComponent];
	newEntry.server = [self server];
	
	//[self saveWithCompletionBlock:^(NSError *error) {}];
	return newEntry;
}



#pragma mark - Removing Entries

- (void)removeEntry:(XEntry *)entry
{
	[_managedObjectContext deleteObject:entry];
}



#pragma mark - Fetched results controllers

- (NSFetchedResultsController *)contentsControllerForDirectory:(XDirectory *)directory
{
	// Fetch all entry objects
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Entry"];

	// Whose parent is the directory given
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"parent == %@", directory]];
	
	// Only need 10 at a time
	[fetchRequest setFetchBatchSize:10];
	
	// Sort by name ascending
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
	[fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	
	// Create controller
	NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																							   managedObjectContext:_managedObjectContext
																								 sectionNameKeyPath:nil
																										  cacheName:[NSString stringWithFormat:@"%@-contents", directory.path]];
	return fetchedResultsController;
}

- (NSFetchedResultsController *)recentlyAccessedFilesController
{
	// Fetch only file objects
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"File"];
	
	// With lastAccessed set
	NSPredicate *predicateTemplate = [NSPredicate predicateWithFormat:@"lastAccessed > $DATE"];
	NSPredicate *predicate = [predicateTemplate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:[NSDate distantPast] forKey:@"DATE"]];
	[fetchRequest setPredicate:predicate];
	
	// Only need 10 at a time
	[fetchRequest setFetchBatchSize:10];
	
	// Sort by last access descending
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"lastAccessed" ascending:NO];
	[fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	
	// Create controller
	NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																								managedObjectContext:_managedObjectContext
																								  sectionNameKeyPath:nil
																										   cacheName:@"recents"];
    return fetchedResultsController;
}



#pragma mark - Recent entries

- (NSArray *)cachedFilesOrderedByLastAccessAscending:(BOOL)ascending
{
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"File"];
	
	// Search filter
	NSPredicate *predicateTemplate = [NSPredicate predicateWithFormat:@"lastAccessed > $DATE"];
	NSPredicate *predicate = [predicateTemplate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObject:[NSDate distantPast] forKey:@"DATE"]];
	[fetchRequest setPredicate:predicate];
	
	// Sort order
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"lastAccessed" ascending:ascending];
	[fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	
	// Set the batch size to infinite
	[fetchRequest setFetchBatchSize:0];
	
	NSError *error = nil;
	NSArray *fetchedObjects = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
	if (error)
	{
		// Something went wrong
		NSLog(@"Error performing fetch request: %@", [error localizedDescription]);
		return nil;
	}
	
	return fetchedObjects;
}



#pragma mark - Reset

- (void)resetPersistentStore
{
	NSURL *storeURL = [NSURL fileURLWithPath:[[NSString documentsPath] stringByAppendingPathComponent:DatabaseFileName]];
	
	// Clear references to current server
	_server = nil;
	[XService sharedXService].remoteService.activeServer = nil;

	// Remove persistent store from the coordinator
	NSPersistentStore *store = [_persistentStoreCoordinator persistentStoreForURL:storeURL];
	NSError *error = nil;
	if (![_persistentStoreCoordinator removePersistentStore:store error:&error])
	{
		XDrvLog(@"Error removing persistent store from coordinator: %@", error);
		return;
	}
	
	// Delete database file
	if (![[NSFileManager defaultManager] removeItemAtPath:storeURL.path error:&error])
	{
		XDrvLog(@"Error deleting database file %@: %@", storeURL.path, error);
		return;
	}
	
	// Create new persistent store
	error = nil;
	[_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
											 configuration:nil
													   URL:storeURL
												   options:nil
													 error:&error];
	if (error)
	{
		XDrvLog(@"Problem creating new persistent store: %@", error);
	}
}

@end









