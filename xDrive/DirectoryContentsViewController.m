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
@property (nonatomic, assign) BOOL _performingFirstUpdate;
@property (nonatomic, assign) DirectoryContentStatus _contentStatus;

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (void)configureCell:(UITableViewCell *)cell forEntry:(XEntry *)entry;

- (UIImage *)iconForEntryType:(NSString *)entryType;

@end



@implementation DirectoryContentsViewController

// Private
@synthesize _fetchedResultsController;
@synthesize _performingFirstUpdate;
@synthesize _contentStatus;

// Public
@synthesize directory;
@synthesize iconTypes;




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
	
	if (!directory.contentsLastUpdated)
	{
		XDrvDebug(@"%@ :: Directory is new; doing first update", directory.path);
		_performingFirstUpdate = YES;
		_contentStatus = DirectoryContentUpdating;
		[[XService sharedXService] updateDirectory:directory forContentsViewController:self];
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
	
	if (_performingFirstUpdate)
	{
		XDrvLog(@"%@ :: Contents not yet loaded. Show activity animation here .....................", directory.path);
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	XDrvDebug(@"%@ :: View will appear", directory.path);
	
	if ([self shouldUpdateContentAutomatically])
	{
		XDrvDebug(@"%@ :: Directory is stale; initiating update", directory.path);
		_contentStatus = DirectoryContentUpdating;
		[[XService sharedXService] updateDirectory:directory forContentsViewController:self];
	}
	else if (!_performingFirstUpdate)
	{
		XDrvDebug(@"%@ :: Directory is fresh", directory.path);
		_contentStatus = DirectoryContentCached;
	}
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

- (BOOL)shouldUpdateContentAutomatically
{
	if (_contentStatus == DirectoryContentUpdating)
	{
		// Update in progress
		return NO;
	}

	XDrvDebug(@"%@ :: Contents last updated %@", directory.path, directory.contentsLastUpdated);
	if ([directory.contentsLastUpdated timeIntervalSinceNow] < (SecondsBetweenContentUpdates * -1))
	{
		// Time passed is greater than specified time interval between content updates
		return YES;
	}

	return NO;
}

- (void)updateDirectoryStatus:(DirectoryContentStatus)status
{
	_contentStatus = status;
	
	switch (status)
	{
		case DirectoryContentCached:
			XDrvDebug(@"%@ :: Status is cached", directory.path);
			break;
			
		case DirectoryContentUpdating:
			XDrvDebug(@"%@ :: Status is updating", directory.path);
			break;
			
		case DirectoryContentUpdateFinished:
			XDrvDebug(@"%@ :: Status is update finished", directory.path);
			if (_performingFirstUpdate)
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
				_performingFirstUpdate = NO;
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
	XDrvDebug(@"%@ :: Changed object %@ at row %i, new row %i", directory.path, anObject, indexPath.row, newIndexPath.row);
    
    switch(type)
    {
            
        case NSFetchedResultsChangeInsert:
			XDrvDebug(@"- Change type INSERT");
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
			XDrvDebug(@"- Change type DELETE");
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
			XDrvDebug(@"- Change type UPDATE");
            //[self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
			[tableView cellForRowAtIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
			XDrvDebug(@"- Change type MOVE");
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








