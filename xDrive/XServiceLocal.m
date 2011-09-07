//
//  XServiceLocal.m
//  xDrive
//
//  Created by Chris Gibbs on 7/5/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

#import "XServiceLocal.h"



@interface XServiceLocal()

@property (nonatomic, strong) XServer *server;

- (XEntry *)entryOfType:(NSString *)type withPath:(NSString *)path;
- (XEntry *)createEntryOfType:(NSString *)type withPath:(NSString *)path;

// Utils
- (NSURL *)applicationDocumentsDirectory;
- (NSString *)entryNameFromPath:(NSString *)path;
@end



@implementation XServiceLocal

@synthesize server;

@synthesize managedObjectModel;
@synthesize managedObjectContext;
@synthesize persistentStoreCoordinator;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

#pragma mark - Server

- (XServer *)activeServer
{
	if (!server)
	{
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"Server"
												  inManagedObjectContext:[self managedObjectContext]];
		[fetchRequest setEntity:entity];

		NSError *error = nil;
		NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
		if (![fetchedObjects count])
			return nil;
		server = [fetchedObjects objectAtIndex:0];
	}
	return server;
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
	// Create the fetch request for the entity.
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	
	// Edit the entity name as appropriate.
	NSEntityDescription *entity = [NSEntityDescription entityForName:type 
											  inManagedObjectContext:managedObjectContext];
	[fetchRequest setEntity:entity];
	
	// Apply a filter predicate
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"path == %@", path]];
	
	// Set the batch size to a suitable number.
	[fetchRequest setFetchBatchSize:1];
	
	NSError *error = nil;
	NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
	if (!fetchedObjects)
	{
		// Something went wrong
		NSLog(@"Error performing fetch request: %@", [error localizedDescription]);
		return nil;
	}
	
	if (![fetchedObjects count])
	{
		// No entries found
		//NSLog(@"No entries of type %@ with a path of %@ were found; returning a new object", type, path);
		return [self createEntryOfType:type withPath:path];
	}
	else
	{
		if ([fetchedObjects count] > 1)
		{
			// Multiple entries found
			NSLog(@"Multiple entries of type %@ exist with the same path: %@; returning the first one", type, path);
		}
		return [fetchedObjects objectAtIndex:0];
	}
}

- (XEntry *)createEntryOfType:(NSString *)type withPath:(NSString *)path
{
	XEntry *newEntry = [NSEntityDescription insertNewObjectForEntityForName:type
													 inManagedObjectContext:managedObjectContext];
	newEntry.path = path;
	newEntry.name = [self entryNameFromPath:path];
	newEntry.server = [self activeServer];
	
	NSError *error = nil;
	if ([managedObjectContext save:&error])
	{
		//NSLog(@"Created new object of type %@ at path %@", type, path);
		return newEntry;
	}
	else
	{
		NSLog(@"Error creating new directory object at path: %@", path);
		return nil;
	}
}

#pragma mark - Fetched Results Controllers

/*- (NSFetchedResultsController *)fetchedResultsControllerForDirectoryContents:(XDirectory *)directory
{
	// Create the fetch request for the entity.
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	
	// Edit the entity name as appropriate.
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Entry" 
											  inManagedObjectContext:managedObjectContext];
	[fetchRequest setEntity:entity];
	
	// Apply a filter predicate
	[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"parent == %@", directory]];
	
	// Set the batch size to a suitable number.
	[fetchRequest setFetchBatchSize:10];
	
	// Edit the sort key as appropriate.
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[fetchRequest setSortDescriptors:sortDescriptors];
	
	// Edit the section name key path and cache name if appropriate.
	// nil for section name key path means "no sections".
	NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] 
															initWithFetchRequest:fetchRequest
															managedObjectContext:managedObjectContext
															  sectionNameKeyPath:nil
																	   cacheName:[NSString stringWithFormat:@"%@-contents", directory.path]];
	return fetchedResultsController;
}*/

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
	if (managedObjectContext != nil)
	{
		return managedObjectContext;
	}
	
	NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
	if (coordinator != nil)
	{
		managedObjectContext = [[NSManagedObjectContext alloc] init];
		[managedObjectContext setPersistentStoreCoordinator:coordinator];
	}
	return managedObjectContext;
}

//
// managedObjectModel
//
// Accessor. If the model doesn't already exist, it is created by merging all of
// the models found in the application bundle.
//
// returns the managed object model for the application.
//
- (NSManagedObjectModel *)managedObjectModel
{
	if (managedObjectModel != nil)
	{
		return managedObjectModel;
	}
	NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"xDrive" withExtension:@"momd"];
	managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
	return managedObjectModel;
}

//
// persistentStoreCoordinator
//
// Accessor. If the coordinator doesn't already exist, it is created and the
// application's store added to it.
//
// returns the persistent store coordinator for the application.
//
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
	if (persistentStoreCoordinator != nil)
	{
		return persistentStoreCoordinator;
	}
	
	NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"xDrive.sqlite"];
	
	NSError *error = nil;
	persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
	if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
												  configuration:nil
															URL:storeURL
														options:nil
														  error:&error])
	{
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}	
	
	return persistentStoreCoordinator;
}

#pragma mark - Utils

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSString *)entryNameFromPath:(NSString *)path
{
	NSArray *components = [path componentsSeparatedByString:@"/"];
	return [components objectAtIndex:[components count] - 1];
}

@end
