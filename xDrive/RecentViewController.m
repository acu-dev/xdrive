//
//  RecentViewController.m
//  xDrive
//
//  Created by Chris Gibbs on 9/23/11.
//  Copyright (c) 2011 Abilene Christian University. All rights reserved.
//

#import "RecentViewController.h"
#import "XService.h"
#import "OpenFileViewController.h"



@interface RecentViewController ()

@property (nonatomic, strong) NSFetchedResultsController *_fetchedResultsController;

@property (nonatomic, strong) NSDictionary *iconTypes;

@end






@implementation RecentViewController

// Private
@synthesize _fetchedResultsController;
@synthesize iconTypes;



- (id)init
{
	self = [super init];
	if (!self) return nil;
	
	_fetchedResultsController = [[XService sharedXService].localService recentlyAccessedFilesController];
	_fetchedResultsController.delegate = self;
	
	return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
	self.iconTypes = nil;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	XFile *file = [_fetchedResultsController objectAtIndexPath:[self.tableView indexPathForSelectedRow]];
	[(id)segue.destinationViewController setFile:file];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
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



#pragma mark - Table view data source

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
    static NSString *CellIdentifier = @"Cell";
    XEntry *entry = [_fetchedResultsController objectAtIndexPath:indexPath];
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	[self configureCell:cell forEntry:entry];
	return cell;
}



#pragma mark - Table view delegate

/*- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}*/


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

/*
 // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed. 
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
 {
 // In the simplest, most efficient, case, reload the table view.
 [self.tableView reloadData];
 }
 */


@end










