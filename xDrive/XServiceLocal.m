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

// Utils
- (NSString *)entryNameFromPath:(NSString *)path;
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
	
    return self;
}

- (id)initForOperationWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    self = [super init];
    if (!self) return nil;
	
	// Set managed object context (See newServiceForOperation)
	_managedObjectContext = managedObjectContext;
    
    return self;
}

- (XServiceLocal *)newServiceForOperation
{
	// Create new private managed object context
	NSManagedObjectContext *privateManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	[privateManagedObjectContext setParentContext:_managedObjectContext];
	
	return [self initForOperationWithManagedObjectContext:privateManagedObjectContext];
}



#pragma mark - Saving

- (void)save
{
	/*
	// Save the child context first
	[childContext performBlock:^{
		NSError *error = nil;
		[childContext save:&error];
		
		// Save the changes on the main context
		[parentContext performBlock:^{
			NSError *parentError = nil;
			[parentContext save:&parentError];
		}];
	}];
	 */
}



#pragma mark - Accessors

- (XServer *)server
{
	if (!_server)
	{
		NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Server"];

		NSError *error = nil;
		NSArray *fetchedObjects = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
		if (![fetchedObjects count])
			return nil;
		_server = [fetchedObjects objectAtIndex:0];
	}
	return _server;
}



#pragma mark - Get/create entries

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
	NSArray *fetchedObjects = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
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
													 inManagedObjectContext:[self managedObjectContext]];
	newEntry.path = path;
	newEntry.name = [self entryNameFromPath:path];
	newEntry.server = _server;
	
	NSError *error = nil;
	if ([[self managedObjectContext] save:&error])
	{
		XDrvDebug(@"Created new %@ object at path %@", type, path);
		return newEntry;
	}
	else
	{
		XDrvLog(@"Error creating new directory object at path: %@", path);
		return nil;
	}
}



#pragma mark - Updating Entries

- (void)mergeChanges:(NSNotification *)notification 
{
    [[self managedObjectContext] performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:) withObject:notification waitUntilDone:YES];
}



#pragma mark - Fetched results controllers

- (NSFetchedResultsController *)contentsControllerForDirectory:(XDirectory *)directory
{
	// Fetch all entry objects
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Entry"];

	// Whose parent is the directory given
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"parent == %@", directory]];
	
	// Set the batch size to a suitable number
	[fetchRequest setFetchBatchSize:10];
	
	// Sort by name ascending
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
	[fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	
	// Edit the section name key path and cache name if appropriate.
	// nil for section name key path means "no sections".
	NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
																							   managedObjectContext:[self managedObjectContext]
																								 sectionNameKeyPath:nil
																										  cacheName:[NSString stringWithFormat:@"%@-contents", directory.path]];
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
	NSArray *fetchedObjects = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];
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



#pragma mark - Core Data stack

//
// managedObjectContext
//
// Accessor. If the context doesn't already exist, it is created and bound to
// the persistent store coordinator for the application
//
// returns the managed object context for the application
//
- (NSManagedObjectContext *)managedObjectContext
{
	if (_managedObjectContext != nil)
	{
		return _managedObjectContext;
	}
	
	NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
	if (coordinator != nil)
	{
		_managedObjectContext = [[NSManagedObjectContext alloc] init];
		[_managedObjectContext setPersistentStoreCoordinator:coordinator];
	}
	return _managedObjectContext;
}

//
// managedObjectModel
//
// Accessor. If the model doesn't already exist, it is created by merging all of
// the models found in the application bundle.
//
// returns the managed object model for the application.
//
/*- (NSManagedObjectModel *)managedObjectModel
{
	if (managedObjectModel != nil)
	{
		return managedObjectModel;
	}
	NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"xDrive" withExtension:@"momd"];
	managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	return managedObjectModel;
}*/

//
// persistentStoreCoordinator
//
// Accessor. If the coordinator doesn't already exist, it is created and the
// application's store added to it.
//
// returns the persistent store coordinator for the application.
//
/*- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
	if (_persistentStoreCoordinator != nil)
	{
		return _persistentStoreCoordinator;
	}
	
	NSString *urlString = [[NSString documentsPath] stringByAppendingPathComponent:DatabaseFileName];
	
	NSError *error = nil;
	_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
	if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
												   configuration:nil
															 URL:[NSURL fileURLWithPath:urlString]
														 options:nil
														   error:&error])
	{
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}	
	
	return _persistentStoreCoordinator;
}*/


@end
