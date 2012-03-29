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


// Content refresh time: 1 hour
static NSTimeInterval SecondsBetweenContentUpdates = 3600;


@interface DirectoryContentsViewController ()

@property (nonatomic, strong) NSFetchedResultsController *_fetchedResultsController;
@property (nonatomic, assign) BOOL _performingFirstUpdate, _shouldHideSearch;
@property (nonatomic, strong) UILabel *_folderEmptyLabel;

- (void)configureCell:(UITableViewCell *)cell forEntry:(XEntry *)entry;

@end



@implementation DirectoryContentsViewController

// Private
@synthesize _fetchedResultsController;
@synthesize _performingFirstUpdate, _shouldHideSearch;
@synthesize _folderEmptyLabel;

// Public
@synthesize directoryViewController;
@synthesize directory;

@synthesize headerView;
@synthesize activityIndicator;
@synthesize arrowImageView;
@synthesize actionLabel, lastUpdatedLabel, folderEmptyLabel;

@synthesize contentStatus = _contentStatus;



#pragma mark - Initialization

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

}

- (void)setDirectory:(XDirectory *)dir
{
	directory = dir;
	
	if (!directory.contentsLastUpdated)
	{
		XDrvDebug(@"%@ :: Updating directory contents for the first time", directory.path);
		_performingFirstUpdate = YES;
		_contentStatus = DirectoryContentUpdating;
		[[XService sharedXService] updateDirectory:directory forContentsViewController:self];
	}
	else
	{
		XDrvDebug(@"%@ :: Displaying directory contents", directory.path);
		_contentStatus = DirectoryContentNotChecked;
		_fetchedResultsController = [[XService sharedXService].localService contentsControllerForDirectory:directory];
		_fetchedResultsController.delegate = self;
		NSError *error = nil;
		if (![_fetchedResultsController performFetch:&error])
		{
			XDrvLog(@"%@ :: Error getting contents: %@", directory.path, error);
		}
	}
	
}



#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	if (!self.title) self.title = directory.name;
	
	// Reset frame origin
	CGRect frame = self.view.frame;
	frame.origin.y = 0;
	self.view.frame = frame;
	
	if (![directory.contents count])
	{
		// Display empty folder label
		_folderEmptyLabel = folderEmptyLabel;
		frame = _folderEmptyLabel.frame;
		frame.origin.y = 175;
		_folderEmptyLabel.frame = frame;
		_folderEmptyLabel.hidden = NO;
		[self.view addSubview:_folderEmptyLabel];
	}
}

- (void)viewDidUnload
{
	[self setActivityIndicator:nil];
	[self setArrowImageView:nil];
	[self setActionLabel:nil];
	[self setLastUpdatedLabel:nil];
	[super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	if ([self shouldUpdateContentAutomatically])
	{
		XDrvDebug(@"%@ :: Directory is stale; Updating directory contents", directory.path);
		_contentStatus = DirectoryContentUpdating;
		[[XService sharedXService] updateDirectory:directory forContentsViewController:self];
	}
	else if (!_performingFirstUpdate)
	{
		_contentStatus = DirectoryContentCached;
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
	
	if (status == DirectoryContentUpdateFinished)
	{
		XDrvDebug(@"%@ :: Directory contents have been updated", directory.path);
		if (_performingFirstUpdate)
		{
			XDrvDebug(@"%@ :: Displaying directory contents", directory.path);
			_fetchedResultsController = [[XService sharedXService].localService contentsControllerForDirectory:directory];
			_fetchedResultsController.delegate = self;
			
			NSError *error = nil;
			if (![_fetchedResultsController performFetch:&error])
			{
				XDrvLog(@"Error performing directory contents fetch: %@", error);
			}
			
			// Reload table
			[self.tableView reloadData];
			_performingFirstUpdate = NO;
			
			// Show contents
			[directoryViewController showDirectoryContentsAnimated:YES];
		}
		
		if ([directory.contents count] && _folderEmptyLabel)
		{
			// Remove folder empty label
			[_folderEmptyLabel removeFromSuperview];
			_folderEmptyLabel = nil;
		}
	}
	else if (status == DirectoryContentUpdateFailed)
	{
		XDrvLog(@"%@ :: Directory update failed", directory.path);
	}
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
	
	cell.imageView.image = [UIImage imageNamed:[[XService sharedXService] iconNameForEntryType:type]];
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
		[directoryViewController navigateToDirectory:(XDirectory *)entry];
	}
	else if ([OpenFileViewController isFileViewable:(XFile *)entry])
	{
		[directoryViewController navigateToFile:(XFile *)entry];
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
	//XDrvDebug(@"%@ :: Changed entry (%@) at row %i, new row %i", directory.path, ((XEntry *)anObject).path, indexPath.row, newIndexPath.row);
    
    switch(type)
    {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
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








