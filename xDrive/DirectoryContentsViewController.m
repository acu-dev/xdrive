//
//  DirectoryContentsViewController.m
//  xDrive
//
//  Created by Christopher Gibbs on 7/6/11.
//  Copyright 2011 Abilene Christian University. All rights reserved.
//

#import "DirectoryContentsViewController.h"
#import "XService.h"
#import "XDriveConfig.h"
#import "OpenFileViewController.h"
#import "UIStoryboard+Xdrive.h"

static NSTimeInterval SecondsBetweenContentUpdates = 300;



@interface DirectoryContentsViewController ()

@property (nonatomic, strong) NSFetchedResultsController *_fetchedResultsController;
@property (nonatomic, assign) BOOL _isFirstUpdate;

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (void)configureCell:(UITableViewCell *)cell forEntry:(XEntry *)entry;
	// Sylizes and fills in data for a specific cell

- (UIImage *)iconForEntryType:(NSString *)entryType;
	// Creates an icon image appropriate for the entry type

@end



@implementation DirectoryContentsViewController

// Private
@synthesize _fetchedResultsController;
@synthesize _isFirstUpdate;

// Public
@synthesize directory;
@synthesize iconTypes;
@synthesize contentStatus;



#pragma mark - Initialization

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
	self.iconTypes = nil;
}



#pragma mark - Accessors

- (void)setDirectory:(XDirectory *)dir
{
	directory = dir;
	XDrvDebug(@"Setting directory to: %@", dir);
	contentStatus = DirectoryContentNotChecked;
	
	if (!directory.contentsLastUpdated)
	{
		XDrvDebug(@"%@ :: Directory is new; doing first update", directory.path);
		_isFirstUpdate = YES;
		[[XService sharedXService] updateEntryAtPath:directory.path forContentsViewController:self];
	}
	else
	{
		XDrvDebug(@"%@ :: Directory has been fetched before; setting up fetched results controller and displaying contents", directory.path);
		_fetchedResultsController = [[XService sharedXService].localService contentsControllerForDirectory:directory];
		_fetchedResultsController.delegate = self;
	
		// Fetch contents
		XDrvDebug(@"%@ :: Fetched results controller performing fetch", directory.path);
		NSError *error = nil;
		if (![_fetchedResultsController performFetch:&error])
		{
			XDrvLog(@"Error performing directory contents fetch: %@", error);
		}
	}
	
}



#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	if (!self.title) self.title = directory.name;
	
	XDrvLog(@"%@ :: View did load", directory.path);
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	XDrvDebug(@"%@ :: View will appear", directory.path);
	
	if (_isFirstUpdate)
	{
		XDrvLog(@"%@ :: Contents not yet loaded. Show activity animation here .....................", directory.path);
	}
	
	/*if ([self shouldUpdateContentAutomatically])
	{
		[_contentsController updateDirectoryContents];
	}*/
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([segue.identifier isEqualToString:@"ViewFile"])
	{
		XFile *file = [_fetchedResultsController objectAtIndexPath:[self.tableView indexPathForSelectedRow]];
		[(id)segue.destinationViewController setXFile:file];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}



#pragma mark - Content Status

- (BOOL)isUpdateInProgress
{
	return (contentStatus == DirectoryContentFetching || contentStatus == DirectoryContentUpdating);
}

- (BOOL)shouldUpdateContentAutomatically
{
	if ([self isUpdateInProgress])
	{
		return NO;
	}
	
	if (!directory.contentsLastUpdated)
	{
		// Directory contents have never been fetched
		return YES;
	}

	if ([directory.contentsLastUpdated timeIntervalSinceNow] < (SecondsBetweenContentUpdates * -1))
	{
		// Last content update was longer ago than time specified between updates
		return YES;
	}

	return NO;
}

- (void)updateDirectoryStatus:(DirectoryContentStatus)status
{
	contentStatus = status;
	
	switch (status)
	{
		case DirectoryContentCached:
			XDrvDebug(@"%@ :: Status is cached", directory.path);
			break;
			
		case DirectoryContentFetching:
		case DirectoryContentUpdating:
			XDrvDebug(@"%@ :: Status is updating", directory.path);
			break;
			
		case DirectoryContentUpdateFinished:
			XDrvDebug(@"%@ :: Status is update finished", directory.path);
			if (_isFirstUpdate)
			{
				XDrvDebug(@"%@ :: Update was first update; setting up fetched results controller and displaying contents", directory.path);
				_fetchedResultsController = [[XService sharedXService].localService contentsControllerForDirectory:directory];
				_fetchedResultsController.delegate = self;
				
				// Fetch contents
				XDrvDebug(@"%@ :: Fetched results controller performing fetch", directory.path);
				NSError *error = nil;
				if (![_fetchedResultsController performFetch:&error])
				{
					XDrvLog(@"Error performing directory contents fetch: %@", error);
				}
				
				// Reload table
				[self.tableView reloadData];
				_isFirstUpdate = NO;
			}
			break;
			
		case DirectoryContentUpdateFailed:
		default:
			XDrvLog(@"%@ :: Status is update failed", directory.path);
			break;
	}
}



#pragma mark - Directory Contents


- (void)displayDirectoryContents
{
	//XDrvDebug(@"%@ :: Creating fetched results controller for directory", directory.path);
	//_fetchedResultsController = [[XService sharedXService].localService contentsControllerForDirectory:directory];
	//_fetchedResultsController.delegate = self;
	
	// Fetch contents
	XDrvDebug(@"%@ :: Performing fetch results", directory.path);
	NSError *error = nil;
	if (![_fetchedResultsController performFetch:&error])
	{
		XDrvLog(@"Error performing directory contents fetch: %@", error);
	}
	
	//[self.tableView reloadData];
}





#pragma mark - Cell customization

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    XEntry *entry = [_fetchedResultsController objectAtIndexPath:indexPath];
    [self configureCell:cell forEntry:entry];
}

- (void)configureCell:(UITableViewCell *)cell forEntry:(XEntry *)entry
{
	cell.textLabel.text = entry.name;
	
	NSString *type = nil;
	if ([entry isKindOfClass:[XFile class]])
	{
		cell.detailTextLabel.text = ((XFile *)entry).sizeDescription;
		type = ((XFile *)entry).type;
	}
	else
	{
		type = @"folder";
	}
	
	cell.imageView.image = [self iconForEntryType:type];
}

- (UIImage *)iconForEntryType:(NSString *)entryType
{
	if (!iconTypes)
	{
		// Load icon mappings from plist
		iconTypes = [[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"File-Types" ofType:@"plist"]] objectForKey:@"Icons"];
	}
	
	// First check for exact match
	NSString *iconName = [iconTypes objectForKey:entryType];
	if (iconName)
	{
		return [UIImage imageNamed:iconName];
	}

	// Match type category
	NSString *category = [[entryType componentsSeparatedByString:@"/"] objectAtIndex:0];
	iconName = [iconTypes objectForKey:category];
	if (iconName)
	{
		return [UIImage imageNamed:iconName];
	}
	
	// Use default
	return [UIImage imageNamed:[iconTypes objectForKey:@"default"]];
}



#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [[_fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	id <NSFetchedResultsSectionInfo> sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];
	return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	XEntry *entry = [_fetchedResultsController objectAtIndexPath:indexPath];
	
	NSString *cellIdentifier = nil;
	if ([entry isKindOfClass:[XDirectory class]])
	{
		// Directory
		cellIdentifier = @"DirCell";
	}
	else if ([OpenFileViewController isFileViewable:(XFile *)entry])
	{
		// Readable file
		cellIdentifier = @"ReadFileCell";
	}
	else
	{
		// Non-readable file
		cellIdentifier = @"NonReadFileCell";
	}
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	[self configureCell:cell forEntry:entry];
	return cell;
}


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	XEntry *entry = [_fetchedResultsController objectAtIndexPath:indexPath];
	
	if ([entry isKindOfClass:[XDirectory class]])
	{
		XDirectory *updatedDir = [[XService sharedXService].localService directoryWithPath:entry.path];
		DirectoryContentsViewController *viewController = [[UIStoryboard mainStoryboard] instantiateViewControllerWithIdentifier:@"directoryContents"];
		[viewController setDirectory:updatedDir];
		[self.navigationController pushViewController:viewController animated:YES];
	}
	else if ([OpenFileViewController isFileViewable:(XFile *)entry])
	{
		// Load file in viewer
		XDrvDebug(@"Opening file entry: %@", entry.path);
		[self performSegueWithIdentifier:@"ViewFile" sender:self];
	}
}



#pragma mark - NSFetchedResultsControllerDelegate   

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type)
    {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            //[self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
			[tableView cellForRowAtIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}




@end








